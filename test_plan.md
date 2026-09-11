# ui2-fr ship test plan

356 specs pass. migrations verified safe. security audit clean (one IDOR fixed). this plan covers what tests can't: do the pages render, do the forms submit, does the flow work end to end.

each section is independent — run them in parallel.

---

## 1. letter lifecycle (web)

- create a new letter from /back_office/letters/new — fill out address, pick a template, pick a return address, add tags, save
- edit the letter — change the template, change rubber stamps, save
- generate a label — does the PDF render?
- mark printed, mark mailed — state transitions work, badges update
- delete a letter — confirm dialog, letter gone from index
- letter index — filters by status work, pagination works, tag filter works

## 2. letter batches

- create a new letter batch — upload a CSV, land on the map fields page
- map fields — column dropdowns populate from CSV headers, save mapping
- process page — shows the letter grid, cost summary renders, MoneyNotice consent banner appears if billing profile exists
- process the batch — letters transition to pending, progress page renders
- mark printed / mark mailed on a batch — bulk state transitions
- retry failed — if any letters failed processing, retry works
- batch show — letter table renders, stats correct, map tab works
- regenerate labels — form renders, submission works

## 3. warehouse orders (web)

- create from /back_office/warehouse/orders/new — address form, line items editor (add SKUs, set quantities), pick tags, save as draft
- edit a draft — change quantities, add/remove line items, save
- send to warehouse — confirm dialog, order dispatches, status changes
- cancel an order — confirm page renders, cancel works
- order show — line items table, status badge, tracking info (if present), billing info
- order index — status filter tabs work, search works, pagination works

## 4. warehouse batches

- create batch — upload CSV, map fields page
- map fields — column mapping works, template picker shows only templates you can see
- process — orders created from CSV rows, progress/errors shown
- batch show — orders table, stats, map tab
- batch index — status filter chips actually filter

## 5. warehouse SKUs, templates, purchase orders

- SKU index — renders, search works, inventory levels shown
- SKU show — detail page, stock levels, PO history, edit form works
- templates — index lists templates, show has line items, create/edit forms work
- purchase orders — create with line items, submit for approval, show page renders with status badge and approval history
- SKU requests — create form, submit, show page (if czar: approve/reject flow)

## 6. admin pages

- /back_office/admin/users — index renders, show page renders user detail, edit form works, flip permissions
- /back_office/admin/common_tags — CRUD works
- /back_office/admin/usps/mailer_ids — index, show, create, edit
- /back_office/admin/usps/payment_accounts — same
- good job dashboard loads
- flipper UI loads
- blazer loads

## 7. API endpoints

- `GET /api/v1/letters` — returns JSON, respects API key scoping
- `POST /api/v1/letters` — creates a letter draft, returns JSON
- `GET /api/v1/letters/:id` — returns letter detail
- `POST /api/v1/letter_queues/instant/:id` — creates instant letter (if queue exists)
- `POST /api/v1/letter_queues/:id` — queues a letter
- `GET /api/v1/warehouse_orders` — returns orders, respects scoping
- `POST /api/v1/warehouse_orders` — creates order with address + SKUs
- `POST /api/v1/warehouse_orders/from_template/:id` — creates from template
- `GET /api/v1/tags` — returns tags
- error responses are JSON (not HTML 500s) for bad auth, missing params, invalid state transitions

## 8. billing & billing profiles

- /back_office/hcb/payment_accounts — index renders existing profiles
- create a new billing profile — OAuth flow redirects to HCB, callback creates profile
- billing history page (/back_office/billing) — renders, shows entries (or empty state)
- billing detail page — shows transfer state, entries
- MoneyNotice appears on: batch process page, warehouse order send-to-warehouse confirm, buy indicia page
- with billing flag OFF: warehouse orders can be created without a billing profile

## 9. return addresses

- index — shows shared + owned addresses
- create — form works, new address appears in index
- edit — form works, changes saved
- set as home — button works, default updates
- return address picker on letter form shows only shared + owned

## 10. public pages

- / — public root renders
- /login — login flow (email code or HCB OAuth)
- /letters/:id — public letter tracking page renders
- /packages/:id — public package tracking renders
- /packages/:id/embed — iframe embed renders, no CORS issues
- /leaderboards — pages render
- /my/mail — logged-in user's mail list

## 11. navigation & chrome

- sidebar — all links go to real pages, no 404s
- sidebar sections gated correctly: warehouse only for warehouse users, admin only for admins, approvals badge only for czars
- command palette (Cmd+K) — opens, search works, results navigate
- keyboard shortcuts modal (?) — opens, lists shortcuts
- mobile — sidebar toggle works, overlay closes it
- flash messages render correctly (success, error, alert)
- action bar — user menu, logout, impersonation banner if impersonating

## 12. static pages & docs

- /back_office/api-docs — renders markdown, copy button works, .md format works
- /back_office/mcp-docs — renders markdown, code blocks formatted
- /back_office/problems — renders for admins, 403 for non-admins

## 13. MCP toolboxes

- connect an MCP client to /mcp — OAuth flow works, consent screen shows checkboxes
- theseus_whoami — returns identity
- theseus_lookup with a letter ID, package ID, tracking number — resolves correctly
- letters_search, letters_show — returns scoped data
- letters_create — creates a draft
- warehouse_orders_search, warehouse_orders_show — returns scoped data
- return_addresses_list — returns only shared + owned (not other users')
- return_addresses_show — can't access other users' addresses (the IDOR we fixed)

## 14. edge cases

- visit any page as a non-admin, non-warehouse user — no crashes, warehouse sections hidden
- visit a letter that belongs to someone else — policy blocks it
- submit a form with validation errors — error messages render, form re-renders with values preserved
- upload a non-CSV file to batch import — error message, redirect back to upload
- upload a CSV with bad encoding — error message, not a 500
