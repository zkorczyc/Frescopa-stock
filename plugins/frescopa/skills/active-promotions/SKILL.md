---
name: active-promotions
description: "Show current active promotions and deals at Frescopa. Use when user asks about promotions, deals, discounts, offers, co jest na promocji, jakie są zniżki, aktualne oferty."
---

# Active Promotions

## When to use
Use this skill when the user wants to know about current deals, discounts, or promotional offers at Frescopa stores.

## Workflow
1. Call `frescopa_active_promotions` to retrieve current promotions
2. For each promotion show: product name, discount/offer details, validity period, applicable stores
3. If a promotion is store-specific, note which locations it applies to

## Format odpowiedzi
Present as a list:

🏷️ **[Promotion Name]**
- Product: [product name]
- Offer: [discount % or deal description]
- Valid: [date range if available]
- Stores: [all stores / specific locations]

## Example
**User**: "Are there any deals at Frescopa right now?"
**Agent**: Calls `frescopa_active_promotions`, presents all active promotions with details.
