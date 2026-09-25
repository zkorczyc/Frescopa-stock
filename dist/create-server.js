import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { jsonText } from "./lib/json.js";
/** Shared MCP tool registrations for stdio and HTTP transports. */
export function createFrescopaServer(sql) {
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
        const data = await sql `
        SELECT *
        FROM public.products
        WHERE is_active = true
          AND (${category ?? null}::text IS NULL OR category = ${category ?? null})
        ORDER BY category, name
      `;
        return jsonText({ products: data });
    });
    server.tool("frescopa_list_stores", "List Fréscopa stores (~100 globally). Filter by region (americas|europe|asia), country, or city.", {
        region: z.enum(["americas", "europe", "asia"]).optional(),
        country: z.string().optional().describe("e.g. Poland, Japan"),
        city: z.string().optional(),
        limit: z.number().int().min(1).max(100).optional().default(100),
    }, async ({ region, country, city, limit }) => {
        const countryValue = country?.trim() || null;
        const cityValue = city?.trim() || null;
        const data = await sql `
        SELECT code, city, name, region, country
        FROM public.store_locations
        WHERE (${region ?? null}::text IS NULL OR region = ${region ?? null})
          AND (${countryValue}::text IS NULL OR country ILIKE ${countryValue})
          AND (${cityValue}::text IS NULL OR city ILIKE ${cityValue})
        ORDER BY region, country, city
        LIMIT ${limit ?? 100}
      `;
        return jsonText({ store_count: data.length, stores: data });
    });
    server.tool("frescopa_store_stock", "Per-store stock. Filter by city, store code (e.g. EU-012, AM-001), region, or country. At least one filter required.", {
        city: z.string().optional(),
        store_code: z.string().optional().describe("e.g. EU-012, AM-001"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
        country: z.string().optional(),
    }, async ({ city, store_code, region, country }) => {
        const cityValue = city?.trim() || null;
        const codeValue = store_code?.trim() || null;
        const countryValue = country?.trim() || null;
        if (!cityValue && !codeValue && !region && !countryValue) {
            throw new Error("Provide at least one of: city, store_code, region, country.");
        }
        const stores = await sql `
        SELECT id, code, city, name, region, country
        FROM public.store_locations
        WHERE (${codeValue}::text IS NULL OR code = ${codeValue})
          AND (${cityValue}::text IS NULL OR city ILIKE ${cityValue})
          AND (${region ?? null}::text IS NULL OR region = ${region ?? null})
          AND (${countryValue}::text IS NULL OR country ILIKE ${countryValue})
      `;
        if (!stores.length) {
            return jsonText({ stores: [], inventory_lines: [], note: "No stores match the filter." });
        }
        const storeIds = stores.map((store) => store.id);
        const rows = await sql `
        SELECT
          i.qty_on_hand,
          i.updated_at,
          json_build_object(
            'demo_product_id', p.demo_product_id,
            'sku', p.sku,
            'name', p.name,
            'category', p.category,
            'unit', p.unit,
            'base_price_cents', p.base_price_cents,
            'currency', p.currency,
            'image_url', p.image_url
          ) AS product,
          json_build_object(
            'code', s.code,
            'city', s.city,
            'name', s.name,
            'region', s.region,
            'country', s.country
          ) AS store
        FROM public.inventory i
        JOIN public.products p ON p.id = i.product_id
        JOIN public.store_locations s ON s.id = i.store_id
        WHERE i.store_id = ANY(${storeIds}::uuid[])
        ORDER BY i.store_id
      `;
        return jsonText({ stores, inventory_lines: rows });
    });
    server.tool("frescopa_search_product_stock", "Search product by name/sku/demo_product_id. Returns stock per store; use region to limit rows (default all ~100 stores).", {
        query: z.string().min(1).describe("e.g. Morning Muse, fp-, IA69R9QG8"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
        in_stock_only: z.boolean().optional().default(false),
    }, async ({ query: qstr, region, in_stock_only }) => {
        const term = `%${qstr.trim()}%`;
        const products = await sql `
        SELECT id, demo_product_id, sku, name, category, unit, base_price_cents, currency, image_url
        FROM public.products
        WHERE is_active = true
          AND (name ILIKE ${term} OR sku ILIKE ${term} OR demo_product_id ILIKE ${term})
      `;
        if (!products.length) {
            return jsonText({ matches: [], note: "No products match the query." });
        }
        const productIds = products.map((product) => product.id);
        const inventory = await sql `
        SELECT
          i.qty_on_hand,
          i.product_id,
          json_build_object('code', s.code, 'city', s.city, 'name', s.name, 'region', s.region, 'country', s.country) AS store
        FROM public.inventory i
        JOIN public.store_locations s ON s.id = i.store_id
        WHERE i.product_id = ANY(${productIds}::uuid[])
          AND (${in_stock_only} = false OR i.qty_on_hand > 0)
          AND (${region ?? null}::text IS NULL OR s.region = ${region ?? null})
      `;
        return jsonText({ products, inventory, store_lines: inventory.length });
    });
    server.tool("frescopa_regional_availability", "Analytics: per region (and country) how many stores stock a product, total qty, availability %. Requires migration v_inventory_by_region.", {
        query: z.string().min(1).describe("Product name fragment or demo_product_id"),
        region: z.enum(["americas", "europe", "asia"]).optional(),
    }, async ({ query: qstr, region }) => {
        const term = `%${qstr.trim()}%`;
        const products = await sql `
        SELECT demo_product_id, name, category
        FROM public.products
        WHERE is_active = true
          AND (name ILIKE ${term} OR demo_product_id ILIKE ${term})
        LIMIT 6
      `;
        if (!products.length)
            return jsonText({ note: "No product match." });
        const ids = products.map((product) => product.demo_product_id);
        const data = await sql `
        SELECT *
        FROM public.v_inventory_by_region
        WHERE demo_product_id = ANY(${ids}::text[])
          AND (${region ?? null}::text IS NULL OR region = ${region ?? null})
        ORDER BY region, country
      `;
        return jsonText({ products, regional_breakdown: data });
    });
    server.tool("frescopa_active_promotions", "Promotion rules valid today (codes, % off, category or single-SKU scope).", {}, async () => {
        const today = new Date().toISOString().slice(0, 10);
        const data = await sql `
        SELECT
          pr.*,
          CASE WHEN p.id IS NULL THEN NULL ELSE json_build_object(
            'demo_product_id', p.demo_product_id,
            'sku', p.sku,
            'name', p.name,
            'category', p.category
          ) END AS product
        FROM public.promotions pr
        LEFT JOIN public.products p ON p.id = pr.product_id
        WHERE pr.valid_from <= ${today}::date
          AND pr.valid_to >= ${today}::date
        ORDER BY pr.discount_percent DESC
      `;
        return jsonText({ as_of: today, promotions: data });
    });
    server.tool("frescopa_products_on_promotion", "Products on promotion TODAY with sale price (promotional_price_cents). Uses view v_products_on_promotion — includes category-wide and SKU-specific deals.", {
        category: z.enum(["coffee", "tea", "machines", "accessories"]).optional(),
        promo_code: z.string().optional().describe("e.g. TEA820, MUSE20"),
        scope: z.enum(["product", "category"]).optional().describe("product = SKU deal only; category = all in category"),
    }, async ({ category, promo_code, scope }) => {
        const today = new Date().toISOString().slice(0, 10);
        const promoCodeValue = promo_code?.trim() || null;
        const data = await sql `
        SELECT *
        FROM public.v_products_on_promotion
        WHERE (${category ?? null}::text IS NULL OR category = ${category ?? null})
          AND (${promoCodeValue}::text IS NULL OR promo_code = ${promoCodeValue})
          AND (${scope ?? null}::text IS NULL OR promotion_scope = ${scope ?? null})
        ORDER BY category, product_name
      `;
        return jsonText({
            as_of: today,
            product_promotion_rows: data.length,
            note: "One product may appear multiple times if several promos apply (category + SKU).",
            products_on_promotion: data,
        });
    });
    server.tool("frescopa_promotion_summary", "Count of SKUs covered per active promo code (category promos = many products).", {}, async () => {
        const today = new Date().toISOString().slice(0, 10);
        const data = await sql `
        SELECT *
        FROM public.v_promotion_summary
        ORDER BY products_on_promotion DESC
      `;
        return jsonText({ as_of: today, promotions: data });
    });
    return server;
}
