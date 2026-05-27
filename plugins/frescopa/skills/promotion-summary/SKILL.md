---
name: promotion-summary
description: "Get a summary of active promotion codes at Frescopa — how many products per code, discount values. Use when user asks about promo codes, promotion overview, podsumowanie promocji, ile produktów w promocji, jakie kody promocyjne są aktywne."
---

# Promotion Summary

## When to use
Use when the user wants a high-level overview of active promotions — how many codes are running, how many products each covers, and overall discount scope.

## Workflow
1. Call `frescopa_promotion_summary` to get all active promotion codes with counts
2. Present each promo code with: code name, number of products, discount type/value
3. Add total: how many products are on promotion across all codes

## Format odpowiedzi
**Active Promotions Summary**

| Code | Products | Discount |
|------|----------|----------|
| SUMMER25 | 8 | 25% off |
| LOYALTY10 | 15 | 10% off |
| FLASH50 | 2 | 50% off |

**Total: 25 products on promotion across 3 active codes.**

## Example
**User**: "Give me a promotion overview / how many promo codes are active?"
**Agent**: Calls `frescopa_promotion_summary`, presents the summary table with totals.
