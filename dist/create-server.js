import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { jsonText } from "./lib/json.js";
/** Shared MCP tool registrations for stdio and HTTP transports. */
export function createFrescopaServer(supabase) {
    const server = new McpServer({
        name: "frescopa",
        version: "1.1.0",
    });
    server.tool("frescopa_list_products", "Active Fréscopa catalog (Adobe Demo project): coffee, tea, machines, accessories. Prices in cents USD; demo_product_id matches site productId.", {
        category: z
            .enum(["coffee", "tea", "machines", "accessories"])
            .optional()
            .describe("coffee | tea | machines | accessories"),
    }, async ({ category }) => {
        let q = supabase.from("products").select("*").eq("is_active", true).order("category").order("name");
        if (category)
            q = q.eq("category", category);
        const { data, error } = await q;
        if (error)
            throw new Error(error.message);
        return jsonText({ products: data ?? [] });
    });
    server.tool("frescopa_list_stores", "List Fréscopa stores (~100 globally). Filter by region (americas|europe|asia), country, or city.", {
        region: z.enum(["americas", "europe", "asia"]).optional(),
        country: z.string().optional().describe("e.g. Poland, Japan"),
        city: z.string().optional(),
        limit: z.number().int().min(1).max(100).optional().default(100),
    }, async ({ region, country, city, limit }) => {
        let q = supabase
            .from("store_locations")
            .select("code, city, name, region, country")
            .order("region")
            .order("country")
            .order("city")
            .limit(limit ?? 100);
        if (region)
            q = q.eq("region", region);
        if (country?.trim())
            q = q.ilike("country", country.trim());
        if (city?.trim())
            q = q.ilike("city", city.trim());
        const { data, error } = await q;
        if (error)
            throw new Error(error.message);
        return jsonText({ store_count: data?.length ?? 0, stores: data ?? [] });
    });
    server.tool("frescopa_store_stock", "Per-store stock. Filter by city, store code (e.g. EU-012, AM-001), region, or country. At least one filter required.", {
        city: z.string().optional(),
        store_code: z.string().optional().describe("e.g. EU-012, AM-001"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
        country: z.string().optional(),
    }, async ({ city, store_code, region, country }) => {
        if (!city?.trim() && !store_code?.trim() && !region && !country?.trim()) {
            throw new Error("Provide at least one of: city, store_code, region, country.");
        }
        let storeQuery = supabase.from("store_locations").select("id, code, city, name, region, country");
        if (store_code?.trim())
            storeQuery = storeQuery.eq("code", store_code.trim());
        if (city?.trim())
            storeQuery = storeQuery.ilike("city", city.trim());
        if (region)
            storeQuery = storeQuery.eq("region", region);
        if (country?.trim())
            storeQuery = storeQuery.ilike("country", country.trim());
        const { data: stores, error: se } = await storeQuery;
        if (se)
            throw new Error(se.message);
        if (!stores?.length)
            return jsonText({ stores: [], inventory_lines: [], note: "No stores match the filter." });
        const storeIds = stores.map((s) => s.id);
        const { data: rows, error: ie } = await supabase
            .from("inventory")
            .select("qty_on_hand, updated_at, product:products(demo_product_id,sku,name,category,unit,base_price_cents,currency,image_url), store:store_locations(code,city,name,region,country)")
            .in("store_id", storeIds)
            .order("store_id");
        if (ie)
            throw new Error(ie.message);
        return jsonText({ stores, inventory_lines: rows ?? [] });
    });
    server.tool("frescopa_search_product_stock", "Search product by name/sku/demo_product_id. Returns stock per store; use region to limit rows (default all ~100 stores).", {
        query: z.string().min(1).describe("e.g. Morning Muse, fp-, IA69R9QG8"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
        in_stock_only: z.boolean().optional().default(false),
    }, async ({ query: qstr, region, in_stock_only }) => {
        const raw = qstr.trim();
        const term = `%${raw}%`;
        const base = () => supabase
            .from("products")
            .select("id, demo_product_id, sku, name, category, unit, base_price_cents, currency, image_url")
            .eq("is_active", true);
        const [{ data: byName, error: e1 }, { data: bySku, error: e2 }, { data: byDemo, error: e3 }] = await Promise.all([
            base().ilike("name", term),
            base().ilike("sku", term),
            base().ilike("demo_product_id", term),
        ]);
        if (e1)
            throw new Error(e1.message);
        if (e2)
            throw new Error(e2.message);
        if (e3)
            throw new Error(e3.message);
        const map = new Map();
        for (const row of [...(byName ?? []), ...(bySku ?? []), ...(byDemo ?? [])]) {
            map.set(row.id, row);
        }
        const products = [...map.values()];
        if (!products.length)
            return jsonText({ matches: [], note: "No products match the query." });
        const ids = products.map((p) => p.id);
        let invQuery = supabase
            .from("inventory")
            .select("qty_on_hand, product_id, store:store_locations(code,city,name,region,country)")
            .in("product_id", ids);
        if (in_stock_only)
            invQuery = invQuery.gt("qty_on_hand", 0);
        const { data: inv, error: ie } = await invQuery;
        if (ie)
            throw new Error(ie.message);
        const filtered = region
            ? (inv ?? []).filter((row) => {
                const store = row.store;
                return store?.region === region;
            })
            : (inv ?? []);
        return jsonText({
            products,
            inventory: filtered,
            store_lines: filtered.length,
        });
    });
    server.tool("frescopa_regional_availability", "Analytics: per region (and country) how many stores stock a product, total qty, availability %. Requires migration v_inventory_by_region.", {
        query: z.string().min(1).describe("Product name fragment or demo_product_id"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
    }, async ({ query: qstr, region }) => {
        const term = `%${qstr.trim()}%`;
        const base = () => supabase.from("products").select("demo_product_id, name, category").eq("is_active", true);
        const [{ data: byName }, { data: byId }] = await Promise.all([
            base().ilike("name", term).limit(3),
            base().ilike("demo_product_id", term).limit(3),
        ]);
        const map = new Map();
        for (const row of [...(byName ?? []), ...(byId ?? [])]) {
            map.set(row.demo_product_id, row);
        }
        const products = [...map.values()];
        if (!products.length)
            return jsonText({ note: "No product match." });
        const ids = products.map((p) => p.demo_product_id);
        let q = supabase
            .from("v_inventory_by_region")
            .select("*")
            .in("demo_product_id", ids)
            .order("region")
            .order("country");
        if (region)
            q = q.eq("region", region);
        const { data, error } = await q;
        if (error)
            throw new Error(error.message);
        return jsonText({ products, regional_breakdown: data ?? [] });
    });
    server.tool("frescopa_active_promotions", "Promotion rules valid today (codes, % off, category or single-SKU scope).", {}, async () => {
        const today = new Date().toISOString().slice(0, 10);
        const { data, error } = await supabase
            .from("promotions")
            .select("*, product:products(demo_product_id,sku,name,category)")
            .lte("valid_from", today)
            .gte("valid_to", today)
            .order("discount_percent", { ascending: false });
        if (error)
            throw new Error(error.message);
        return jsonText({ as_of: today, promotions: data ?? [] });
    });
    server.tool("frescopa_products_on_promotion", "Products on promotion TODAY with sale price (promotional_price_cents). Uses view v_products_on_promotion — includes category-wide and SKU-specific deals.", {
        category: z.enum(["coffee", "tea", "machines", "accessories"]).optional(),
        promo_code: z.string().optional().describe("e.g. TEA820, MUSE20"),
        scope: z.enum(["product", "category"]).optional().describe("product = SKU deal only; category = all in category"),
    }, async ({ category, promo_code, scope }) => {
        const today = new Date().toISOString().slice(0, 10);
        let q = supabase.from("v_products_on_promotion").select("*").order("category").order("product_name");
        if (category)
            q = q.eq("category", category);
        if (promo_code?.trim())
            q = q.eq("promo_code", promo_code.trim());
        if (scope)
            q = q.eq("promotion_scope", scope);
        const { data, error } = await q;
        if (error)
            throw new Error(error.message);
        return jsonText({
            as_of: today,
            product_promotion_rows: data?.length ?? 0,
            note: "One product may appear multiple times if several promos apply (category + SKU).",
            products_on_promotion: data ?? [],
        });
    });
    server.tool("frescopa_promotion_summary", "Count of SKUs covered per active promo code (category promos = many products).", {}, async () => {
        const today = new Date().toISOString().slice(0, 10);
        const { data, error } = await supabase
            .from("v_promotion_summary")
            .select("*")
            .order("products_on_promotion", { ascending: false });
        if (error)
            throw new Error(error.message);
        return jsonText({ as_of: today, promotions: data ?? [] });
    });
    return server;
}
