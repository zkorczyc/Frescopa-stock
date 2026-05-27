---
name: check-product-stock
description: "Check stock availability for a specific product across Frescopa stores, optionally filtered by region or showing only in-stock locations. Use when user asks about product availability, stock levels, where to find a product, czy produkt jest dostępny, ile zostało, sprawdź stan magazynowy, dostępność w regionie."
---

# Check Product Stock

## When to use
Use this skill when the user wants to know if a specific product is available in Frescopa stores — by name, SKU, or product ID.

## Workflow
1. Call `frescopa_search_product_stock` with the product name or SKU from the user's query
2. Optionally pass `region` (e.g. "Europe", "Asia") if user specified a region
3. Optionally pass `in_stock_only: true` if user only wants locations where product is available
4. Review the inventory array — each entry shows `qty_on_hand` and store details (city, name, code)
5. If `qty_on_hand > 0` → product is in stock at that location
6. If `qty_on_hand = 0` → out of stock at that location

## Format odpowiedzi
Present results as a table:

| Store | City | Qty |
|-------|------|-----|
| Fréscopa SOMA | San Francisco | 20 ✅ |
| Fréscopa West Loop | Chicago | 0 ❌ |

Follow with one sentence summary: "Product X is available in N locations."

## Example
**User**: "Where is Golden Monkey Tea in stock?"
**Agent**: Calls `frescopa_search_product_stock` with query "Golden Monkey Tea", then presents the table showing availability per store.
