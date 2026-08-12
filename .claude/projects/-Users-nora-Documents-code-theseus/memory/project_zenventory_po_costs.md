---
name: zenventory PO cost data is immutable
description: Historical PO data in Zenventory cannot be edited — zero-cost PO items are permanent, only fix is declared_unit_cost_override on the SKU
type: project
---

Zenventory PO cost data is immutable once created. If a PO was entered with `unitCost: 0`, it stays that way forever.

**Why:** discovered during sev1 fix (ticket #117) — 38/480 PO line items in Zenventory have zero costs. Can't be retroactively fixed.

**How to apply:** when building features around PO costs, never assume Zenventory PO data can be corrected. The workaround is `declared_unit_cost_override` on the SKU model. Don't build alerting/emails around historic zero-cost PO data since it would just spam forever.
