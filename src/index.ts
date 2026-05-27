/**
 * Frescopa MCP — stdio server reading catalog / inventory / promotions from Supabase.
 * Configure Cursor / Adobe AI Assistant with command: node path/to/Frescopa/dist/index.js
 */
import "dotenv/config";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

function requireEnv(name: string): string {
  const v = process.env[name]?.trim();
  if (!v) throw new Error(`Missing env ${name}. Copy Frescopa/.env.example to Frescopa/.env`);
  return v;
}

function getClient(): SupabaseClient {
  const url = requireEnv("SUPABASE_URL");
  const key = requireEnv("SUPABASE_ANON_KEY");
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function jsonText(data: unknown): { content: { type: "text"; text: string }[] } {
  return {
    content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
  };
}

async function main(): Promise<void> {
  const supabase = getClient();

  const server = new McpServer({
    name: "frescopa",
    version: "1.0.0",
  });

  server.tool(
    "frescopa_list_products",
    "Active Fréscopa catalog (Adobe Demo project): coffee, tea, machines, accessories. Prices in cents USD; demo_product_id matches site productId.",
    {
      category: z
        .enum(["coffee", "tea", "machines", "accessories"])
        .optional()
        .describe("coffee | tea | machines | accessories"),
    },
    async ({ category }) => {
      let q = supabase.from("products").select("*").eq("is_active", true).order("category").order("name");
      if (category) q = q.eq("category", category);
      const { data, error } = await q;
      if (error) throw new Error(error.message);
      return jsonText({ products: data ?? [] });
    }
  );

  server.tool(
    "frescopa_store_stock",
    "Per-store stock (San Francisco, New York, Chicago). Pass city or store code (SF-01, NYC-01, CHI-01).",
    {
      city: z.string().optional().describe("e.g. San Francisco"),
      store_code: z.string().optional().describe("e.g. SF-01"),
    },
    async ({ city, store_code }) => {
      if (!city?.trim() && !store_code?.trim()) {
        throw new Error("Provide city or store_code.");
      }
      let storeQuery = supabase.from("store_locations").select("id, code, city, name");
      if (store_code?.trim()) storeQuery = storeQuery.eq("code", store_code.trim());
      if (city?.trim()) storeQuery = storeQuery.ilike("city", city.trim());

      const { data: stores, error: se } = await storeQuery;
      if (se) throw new Error(se.message);
      if (!stores?.length) return jsonText({ stores: [], lines: [], note: "No stores match the filter." });

      const storeIds = stores.map((s) => s.id);
      const { data: rows, error: ie } = await supabase
        .from("inventory")
        .select(
          "qty_on_hand, updated_at, product:products(demo_product_id,sku,name,category,unit,base_price_cents,currency,image_url), store:store_locations(code,city,name)"
        )
        .in("store_id", storeIds)
        .order("store_id");
      if (ie) throw new Error(ie.message);

      return jsonText({ stores, inventory_lines: rows ?? [] });
    }
  );

  server.tool(
    "frescopa_search_product_stock",
    "Search by name fragment, sku, or Adobe demo_product_id (same as productId in composer). Returns qty per store.",
    {
      query: z.string().min(1).describe("e.g. Morning Muse, fp-, IA69R9QG8"),
    },
    async ({ query: qstr }) => {
      const raw = qstr.trim();
      const term = `%${raw}%`;
      const base = () =>
        supabase
          .from("products")
          .select("id, demo_product_id, sku, name, category, unit, base_price_cents, currency, image_url")
          .eq("is_active", true);

      const [{ data: byName, error: e1 }, { data: bySku, error: e2 }, { data: byDemo, error: e3 }] =
        await Promise.all([
          base().ilike("name", term),
          base().ilike("sku", term),
          base().ilike("demo_product_id", term),
        ]);
      if (e1) throw new Error(e1.message);
      if (e2) throw new Error(e2.message);
      if (e3) throw new Error(e3.message);
      type P = NonNullable<typeof byName>[number];
      const map = new Map<string, P>();
      for (const row of [...(byName ?? []), ...(bySku ?? []), ...(byDemo ?? [])]) {
        map.set(row.id, row);
      }
      const products = [...map.values()];
      if (!products.length) return jsonText({ matches: [], note: "No products match the query." });

      const ids = products.map((p) => p.id);
      const { data: inv, error: ie } = await supabase
        .from("inventory")
        .select(
          "qty_on_hand, product_id, store:store_locations(code,city,name)"
        )
        .in("product_id", ids);
      if (ie) throw new Error(ie.message);

      return jsonText({ products, inventory: inv ?? [] });
    }
  );

  server.tool(
    "frescopa_active_promotions",
    "Promotions valid today (valid_from / valid_to); includes promo_code when set (e.g. TEA820, COFFEE7).",
    {},
    async () => {
      const today = new Date().toISOString().slice(0, 10);
      const { data, error } = await supabase
        .from("promotions")
        .select("*, product:products(sku,name)")
        .lte("valid_from", today)
        .gte("valid_to", today)
        .order("discount_percent", { ascending: false });
      if (error) throw new Error(error.message);
      return jsonText({ as_of: today, promotions: data ?? [] });
    }
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
