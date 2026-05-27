# Fréscopa × Supabase × MCP (Adobe Demo–aligned)

**Model Context Protocol** server for Fréscopa catalog, per-store stock, and promotions from **Supabase**.

| Mode | Use case |
|------|----------|
| **stdio** (`npm start`) | Cursor, Claude Desktop on your Mac |
| **HTTP** (`npm run start:http`) | Adobe AI Assistant, any remote app — public URL |

Data model matches the **Adobe Demo System** Fréscopa web project: `project.products` **names** and **USD list prices** (stored as `base_price_cents`), plus a stable **`demo_product_id`** equal to composer `productId` (e.g. `IA69R9QG8`, `rkX5zwiC$`). **Availability** is mock seed data (SF / NYC / Chicago) for assistant demos—not live commerce inventory. Public project docs: [Fréscopa web](https://docs.adobedemo.com/projects/public-projects/frescopa/web).

## Repo layout

| Path | Purpose |
|------|---------|
| `supabase/migrations/20250527000000_frescopa_init.sql` | Tables, RLS (`anon`/`authenticated` read-only), seed |
| `src/index.ts` | MCP stdio entry |
| `src/http.ts` | MCP HTTP entry (`POST /mcp`) |
| `src/create-server.ts` | Shared tools |
| `.env.example` | Env template |

## Supabase setup

1. Prefer a **dedicated** Supabase project for this demo (generic table names in `public`).

2. **SQL**: Dashboard → **SQL Editor** → paste the full file `supabase/migrations/20250527000000_frescopa_init.sql` → **Run**.  
   If the database already has the schema, apply follow-ups from `supabase/migrations/` in order (e.g. `20250527120000_add_product_images.sql` for `image_url`).

**Supabase Git** ([Frescopa-stock](https://github.com/zkorczyc/Frescopa-stock)): push migrations to `main`; linked projects deploy new files automatically. After push, confirm the migration ran under **Database → Migrations** (or run the SQL manually once).

3. **API**: Project Settings → **API** — set in `Frescopa/.env`:
   - `SUPABASE_URL` = `https://uxlccvzhuwzwzrmqunml.supabase.co`
   - `SUPABASE_ANON_KEY` = **anon public** key from the same page (do not commit)

### If you already ran an older Frescopa migration (Polish SKUs / no `demo_product_id`)

That schema is incompatible. Either create a **new** Supabase project, or in SQL drop dependent objects and re-run the init file (example order): `inventory` → `promotions` → `products` → `store_locations` (watch FKs), then run the migration again.

## Local build

```bash
cd /Users/zkorczyc/Projects/Frescopa
cp .env.example .env   # skip if .env already exists
npm install
npm run build
```

## Cursor `mcp.json` snippet

Update path if you moved the project from `adobe/agents/Frescopa`.

```json
{
  "mcpServers": {
    "frescopa": {
      "command": "node",
      "args": ["/Users/zkorczyc/Projects/Frescopa/dist/index.js"],
      "env": {
        "SUPABASE_URL": "https://uxlccvzhuwzwzrmqunml.supabase.co",
        "SUPABASE_ANON_KEY": "eyJ..."
      }
    }
  }
}
```

## MCP tools

| Tool | Role |
|------|------|
| `frescopa_list_products` | Catalog; optional `category`: `coffee` \| `tea` \| `machines` \| `accessories` |
| `frescopa_list_stores` | ~100 stores; filter `region`: `americas` \| `europe` \| `asia` |
| `frescopa_store_stock` | Stock by store — `city`, `store_code` (`EU-012`), `region`, or `country` |
| `frescopa_search_product_stock` | Product search + per-store qty; optional `region`, `in_stock_only` |
| `frescopa_regional_availability` | **Insights:** stores in stock, total qty, availability % by region/country |
| `frescopa_active_promotions` | Promotion rules active today |
| `frescopa_products_on_promotion` | **Which products** are on promo now + sale price |
| `frescopa_promotion_summary` | How many SKUs each promo code covers |

Run **`20250527150000_expand_promotions.sql`** after the store migration for promo data (TEA820, COFFEE7, MUSE20, …).

After **`20250527140000_scale_stores_global_100.sql`**: 100 stores (35 Americas, 40 Europe, 25 Asia), ~2 500 inventory rows, view `v_inventory_by_region`.

**Price convention:** `base_price_cents` is integer USD cents (e.g. `999` = $9.99). `currency` defaults to `USD`.  
**Images:** `image_url` matches `project.products.image` on the Fréscopa demo site (S3 assets).

## Remote MCP URL (HTTP)

For apps that **cannot** run `node` locally (e.g. Adobe AI Assistant in the browser):

### 1. Run locally (smoke test)

```bash
npm run build
# set MCP_API_KEY in .env (recommended)
npm run start:http
```

- Health: `http://localhost:3000/health`
- MCP endpoint: **`http://localhost:3000/mcp`** (Streamable HTTP, **POST**)
- If `MCP_API_KEY` is set, send header: `Authorization: Bearer <MCP_API_KEY>`

### 2. Deploy (e.g. Render, Fly.io, Railway)

1. Push this repo to GitHub ([Frescopa-stock](https://github.com/zkorczyc/Frescopa-stock)).
2. Create a **Web Service** (Node 20), build `npm install && npm run build`, start `npm run start:http`.
3. Set env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MCP_API_KEY` (required in production).
4. Use the public URL, e.g. **`https://frescopa-mcp.onrender.com/mcp`**.

`render.yaml` in the repo is a starter blueprint for Render.

### 3. Register in Adobe AI Assistant

In the assistant / connector admin UI, add a **custom MCP** (exact labels vary):

- **URL:** `https://<your-host>/mcp`
- **Transport:** Streamable HTTP (or “HTTP” / “Remote MCP” if offered)
- **Auth:** Bearer token = your `MCP_API_KEY`

Until this is registered, the assistant will only show built-in connectors (AEM, Slack, …) — not Frescopa.

### stdio vs URL

| | stdio | HTTP |
|---|--------|------|
| URL | none (`node dist/index.js`) | `https://…/mcp` |
| Cursor | yes | only if Cursor supports remote MCP URL |
| Adobe Assistant cloud | no | **yes** |

## Skill hint (Adobe AI Assistant)

Tell the model to **always** fetch prices and stock via `frescopa_*` tools, never from memory; on connection errors, report failure and do not invent numbers. Mention that `demo_product_id` ties a row to the **same** `productId` used on the Fréscopa demo site.

## Security

- Do not commit `.env` or **service role** keys.  
- Demo is safe with **anon** + RLS limited to `SELECT`.  
- For writes later, use Edge Functions or a dedicated role—not broad `anon` `INSERT`.
- **HTTP:** always set `MCP_API_KEY` on public deploy; Supabase stays read-only via publishable key.
