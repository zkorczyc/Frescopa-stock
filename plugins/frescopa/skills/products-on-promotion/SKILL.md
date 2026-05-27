---
name: products-on-promotion
description: "Show which Frescopa products are currently on promotion with promotional prices. Use when user asks about deals, sale products, what's discounted, które produkty są w promocji, co jest na wyprzedaży, jakie są zniżki na produkty, promocyjne ceny."
---

# Products on Promotion

## When to use
Use when the user wants to know which specific products have a promotional price right now — including the original price, promo price, and discount amount.

## Workflow
1. Call `frescopa_products_on_promotion` to get all products currently on promotion
2. For each product show: name, original price, promotional price, discount % or amount
3. Sort by biggest discount first

## Format odpowiedzi
List promoted products:

🏷️ **Golden Monkey Tea** — ~~$9.99~~ **$7.49** (save 25%)
🏷️ **Morning Muse** — ~~$12.99~~ **$9.99** (save 23%)

Total: X products on promotion.

## Example
**User**: "What products are on sale right now?"
**Agent**: Calls `frescopa_products_on_promotion`, lists all discounted products with prices and savings.
