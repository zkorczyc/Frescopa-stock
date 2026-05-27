---
name: regional-availability
description: "Compare product availability across regions (Europe vs Asia, North America vs Europe, etc.). Use when user asks about regional stock, availability by region, compare regions, dostępność w Europie, porównaj regiony, który region ma więcej produktu."
---

# Regional Availability

## When to use
Use when the user wants to compare how a product is stocked across different regions or continents — e.g. "Is Morning Muse available in Europe?" or "Compare stock of Golden Monkey Tea between Asia and US".

## Workflow
1. Call `frescopa_regional_availability` with the product name/SKU and the regions to compare
2. Summarize total qty per region
3. Highlight which region has the best availability
4. Note any regions where the product is completely out of stock

## Format odpowiedzi
**Morning Muse — Regional Availability**

| Region | Stores | Total Qty | Status |
|--------|--------|-----------|--------|
| Europe | 3 | 85 | ✅ Well stocked |
| Asia | 2 | 12 | ⚠️ Low |
| North America | 4 | 0 | ❌ Out of stock |

Follow with: "Best availability in [Region]. Consider restocking in [Region]."

## Example
**User**: "How is Morning Muse availability in Europe vs Asia?"
**Agent**: Calls `frescopa_regional_availability` for Morning Muse across Europe and Asia, presents comparison table.
