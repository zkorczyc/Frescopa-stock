---
name: store-inventory
description: "Get full inventory for a specific Frescopa store. Use when user asks about what's available at a particular store, store stock, inventory at location, co jest w sklepie, pełny asortyment sklepu."
---

# Store Inventory

## When to use
Use this skill when the user wants to see all products available at a specific Frescopa store location.

## Workflow
1. Call `frescopa_store_stock` with the store code or city name
2. List all products with their `qty_on_hand`
3. Group by category if multiple categories are present
4. Highlight items that are low stock (qty < 5) or out of stock (qty = 0)

## Format odpowiedzi
Present as a grouped list by category:

**Category: Tea**
- Golden Monkey Tea — 20 in stock
- Morning Muse — 3 in stock ⚠️ (low)

**Category: Coffee**
- Espresso Blend — 0 ❌ (out of stock)

## Example
**User**: "What's available at the San Francisco store?"
**Agent**: Calls `frescopa_store_stock` for SF-01, returns full inventory grouped by category.
