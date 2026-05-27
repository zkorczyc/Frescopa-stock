---
name: list-stores
description: "List Frescopa store locations, optionally filtered by region or country. Use when user asks about store locations, which cities have Frescopa, stores in Europe/Asia/US, gdzie są sklepy Frescopa, lista lokalizacji, jakie miasta."
---

# List Stores

## When to use
Use when the user wants to know where Frescopa stores are located — all stores, or filtered by region (Europe, Asia, US, etc.) or country.

## Workflow
1. Call `frescopa_list_stores` — pass `region` parameter if the user specified a region (e.g. "Europe", "Asia", "North America")
2. Present the list grouped by region or country
3. Include store name, city, and store code

## Format odpowiedzi
Group by region if multiple regions returned:

**🌍 Europe**
- Fréscopa Warsaw (WAW-01) — Warsaw
- Fréscopa London (LON-01) — London

**🌏 Asia**
- Fréscopa Tokyo (TYO-01) — Tokyo

If filtered to one region, just list without grouping.

## Example
**User**: "Which cities in Europe have a Frescopa store?"
**Agent**: Calls `frescopa_list_stores` with `region: "Europe"`, lists all European locations.
