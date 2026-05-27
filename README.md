# Fréscopa × Supabase × MCP (Adobe Demo–aligned)

Lightweight **Model Context Protocol (stdio)** server: catalog, per-store stock, and promotions from **Supabase**. Wire it to Cursor or Adobe AI Assistant as a custom MCP.

Data model matches the **Adobe Demo System** Fréscopa web project: `project.products` **names** and **USD list prices** (stored as `base_price_cents`), plus a stable **`demo_product_id`** equal to composer `productId` (e.g. `IA69R9QG8`, `rkX5zwiC$`). **Availability** is mock seed data (SF / NYC / Chicago) for assistant demos—not live commerce inventory. Public project docs: [Fréscopa web](https://docs.adobedemo.com/projects/public-projects/frescopa/web).

## Repo layout

| Path | Purpose |
|------|---------|
| `supabase/migrations/20250527000000_frescopa_init.sql` | Tables, RLS (`anon`/`authenticated` read-only), seed |
| `src/index.ts` | MCP server + tools |
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
| `frescopa_store_stock` | Stock by store — pass `city` (e.g. `San Francisco`) **or** `store_code` (`SF-01`, `NYC-01`, `CHI-01`) |
| `frescopa_search_product_stock` | Search name / `sku` / `demo_product_id` |
| `frescopa_active_promotions` | Promotions valid “today”; includes `promo_code` (`TEA820`, `COFFEE7`) when present |

**Price convention:** `base_price_cents` is integer USD cents (e.g. `999` = $9.99). `currency` defaults to `USD`.  
**Images:** `image_url` matches `project.products.image` on the Fréscopa demo site (S3 assets).

## Skill hint (Adobe AI Assistant)

Tell the model to **always** fetch prices and stock via `frescopa_*` tools, never from memory; on connection errors, report failure and do not invent numbers. Mention that `demo_product_id` ties a row to the **same** `productId` used on the Fréscopa demo site.

## Security

- Do not commit `.env` or **service role** keys.  
- Demo is safe with **anon** + RLS limited to `SELECT`.  
- For writes later, use Edge Functions or a dedicated role—not broad `anon` `INSERT`.
