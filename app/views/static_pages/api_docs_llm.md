# Theseus API Reference (for LLMs)

## What is Theseus?

Theseus is Hack Club's internal mail and warehouse system. It handles the physical side of Hack Club — printing and mailing letters/postcards to teenagers, and shipping packages (sticker drops, welcome kits, prize fulfillment) through a warehouse partner.

Theseus is not a general-purpose mailing API. It exists to serve Hack Club programs. If you're building an integration, you're probably working on one of these:

- **Onboarding flows** — a new Hack Clubber signs up for something (High Seas, Boba Drops, a grant program) and should receive a welcome letter or a package in the mail. Your code calls Theseus when the user hits the right milestone.
- **Prize fulfillment** — a Hack Clubber earns something (ships a project, wins a vote, completes a challenge) and your platform needs to send them a reward. Letters for small stuff, warehouse orders for physical prizes.
- **Transactional postcards** — something happened and you want to celebrate it with a physical postcard right now, not in a batch later. This is what Instant Queues are for.
- **Bulk mailings** — you have a list of people who need letters (event invitations, program updates). Queue them all into a Batch Queue and a human will batch and send them.
- **User-facing tracking** — you want to show a Hack Clubber where their mail or package is. The public API and the embeddable tracking widget are for this.

If your integration doesn't fit one of these patterns, you might be overcomplicating it. Ask Nora (the person who runs Theseus) before building something novel.

**The base URL is `https://mail.hackclub.com`.** All endpoint paths in this document are relative to that.

**If you are an LLM building an integration against this API:** read this entire document before writing code. There are constraints (blocked countries, idempotency, address validation) that will bite you if you skip ahead to the endpoint you think you need.

## Before you write any code

**Always use idempotency keys.** Every endpoint that creates something (letters, warehouse orders) accepts an `idempotency_key` field. Use it. Always. If your code retries a request, double-fires from a queue, or runs twice because of a deploy, the idempotency key prevents duplicate mail from going out. Duplicate mail wastes real postage money and confuses real people. Generate a key that's deterministic for the intent — `"{program}-{user_id}-{action}"` is a good pattern. Do not use random UUIDs as idempotency keys — they defeat the purpose.

**Always use ISO 3166 alpha-2 country codes.** The API will try to parse "United States", "USA", "US", "Amerika", and even Cyrillic country names. It is shockingly good at this. But "shockingly good" is not "perfect" — use `US`, `CA`, `GB`, etc. Same for states: `VT` not `Vermont`.

**Validate addresses before sending.** The API requires `first_name`, `line_1`, `city`, `state`, `postal_code`, and `country` on every address. If any of these are missing or empty, the request will fail. Do not send requests with placeholder or obviously fake addresses — these cost real postage and waste warehouse labor.

**Some countries are blocked for warehouse shipments.** You cannot ship packages to: Iran (IR), Palestine (PS), Cuba (CU), North Korea (KP), or Russia (RU). The API will reject these with a validation error. Letters are not blocked by country but use good judgment.

**This system sends real physical mail.** Every successful API call results in a real letter being printed or a real package being shipped. There is no sandbox or test mode. Do not fire test requests against production. If you are unsure whether a request will do what you want, read the docs again or ask a human.

**All requests must send `Content-Type: application/json`.** The API expects JSON request bodies. If you forget this header, you'll get silent 400 errors.

**There is no pagination or rate limiting.** List endpoints return all results. There are no page/cursor params and no 429 responses. That said, don't fire 500 requests in parallel — be reasonable, especially for endpoints that do real work (instant queues, warehouse orders).

**Watch the nesting differences between letters and warehouse orders.** This is the single most common mistake. Letters have a flat request body — `address`, `recipient_email`, `idempotency_key`, `metadata` are all top-level. Warehouse orders nest most fields under a `warehouse_order` key — `recipient_email`, `tags`, `idempotency_key`, `metadata` go inside `warehouse_order`, while `address` and `contents` stay top-level. Get this wrong and you'll get missing parameter errors.

---

## Authentication

All requests require an API key in the `Authorization` header:

```
Authorization: Bearer th_apk_live_yourKeyHere
```

There are two API systems:
- **Internal API** (`/api/v1/`) — for backend integrations that send mail and create orders. Uses internal `APIKey` tokens.
- **Public API** (`/api/public/v1/`) — for end-user-facing apps that show a person their own mail. Uses `Public::APIKey` tokens.

Most integrations use the internal API. If you're building something that shows a user their incoming mail/packages, use the public API.

---

## Sending Mail

There are two ways to send mail, and which one you use matters:

### Batch Queues (most common)

Letters go into a queue. A human (Nora) reviews them, batches them up, and generates shipping labels. This is the right choice for bulk mailings, welcome letters, prize fulfillment — anything where a few hours of delay is fine.

**Submit a letter to a batch queue:**
```
POST /api/v1/letter_queues/:queue_slug
```

The queue slug is assigned when your queue is set up (ask Nora).

**Request body:**
```json
{
  "address": {
    "first_name": "Fiona",
    "last_name": "Hackworth",
    "line_1": "123 Sesame St",
    "line_2": "Apt 4",
    "city": "Shelburne",
    "state": "VT",
    "postal_code": "05482",
    "country": "US"
  },
  "recipient_email": "fiona@hackclub.com",
  "rubber_stamps": "hey Fiona! hope you like stickers!",
  "idempotency_key": "onboarding-fiona-2026-03",
  "metadata": {
    "source": "onboarding",
    "wave": 3
  }
}
```

**Address fields:**
| Field | Required | Notes |
|---|---|---|
| `first_name` | yes | |
| `last_name` | no | |
| `line_1` | yes | street address |
| `line_2` | no | apt/unit/suite |
| `city` | yes | |
| `state` | yes | use abbreviations (`VT`, `CA`) |
| `postal_code` | yes | |
| `country` | yes | use ISO 3166 alpha-2 (`US`, `CA`, `GB`) |

**Other fields:**
| Field | Required | Notes |
|---|---|---|
| `recipient_email` | no | helpful for tracking, strongly recommended |
| `rubber_stamps` | no | custom text printed on the letter |
| `idempotency_key` | no | **use it anyway. always.** |
| `metadata` | no | arbitrary JSON object, stored and returned as-is. use for your internal IDs, feature flags, template variables, whatever. |
| `return_address_name` | no | overrides the "from" name on the letter |

**Response (201):**
```json
{
  "id": "ltr!abc123",
  "sender": "usr!def456",
  "status": "queued",
  "tags": ["your-project"],
  "return_address": {
    "name": "Hack Club",
    "line_1": "...",
    "city": "...",
    "state": "...",
    "postal_code": "...",
    "country": "US"
  },
  "address": {
    "first_name": "Fiona",
    "last_name": "Hackworth"
  },
  "rubber_stamps": "hey Fiona! hope you like stickers!",
  "metadata": { "source": "onboarding", "wave": 3 }
}
```

The letter starts in `queued` status. It moves to `pending` when batched, then `printed`, `mailed`, and finally `received`.

### Instant Queues

Instant Queues skip the human review step. Your request prints a postcard, buys postage, and drops it in the outbox — all synchronously. The request takes a few seconds because it's doing real work.

**Submit a letter to an instant queue:**
```
POST /api/v1/letter_queues/instant/:queue_slug
```

Same request body as batch queues. Same fields, same validations.

**Key differences from batch queues:**
- **Postcards only.** Instant queues print postcards, not letters in envelopes.
- **Slower requests.** Expect 2-5 seconds per request. The API is printing and buying postage.
- **Postage is charged immediately.** If the queue uses indicia postage, money moves the moment you call this.
- **Status starts at `pending`**, not `queued` — there's no queue step.
- **Errors are immediate.** If something breaks (bad address, postage failure), you find out right now, not later.

Use instant queues for transactional postcards ("your project shipped!", "congrats on finishing!"). Use batch queues for everything else.

---

## Checking on a letter

```
GET /api/v1/letters/:id
```

`:id` is the letter's public ID (e.g., `ltr!abc123`).

Returns the same letter object shape as the create response. Use this to poll for status changes.

**Letter lifecycle:** `queued` → `pending` → `printed` → `mailed` → `received`

---

## The Warehouse (packages)

The warehouse API creates shipping orders fulfilled by Hack Club's warehouse partner. You tell the API what to ship and where; it dispatches the order and the warehouse ships it.

**Important:** Warehouse access requires authorization. Talk to Nora before using these endpoints — your API key needs the `can_warehouse?` permission.

### Creating an order from a template

Templates are pre-configured bundles (welcome packs, prize kits, etc.). If you're always sending the same thing, ask Nora to set up a template.

```
POST /api/v1/warehouse_orders/from_template/:template_id
```

**Request body:**
```json
{
  "address": {
    "first_name": "Zach",
    "last_name": "Latta",
    "line_1": "15 Falls Road",
    "city": "Shelburne",
    "state": "VT",
    "postal_code": "05482",
    "country": "US"
  },
  "warehouse_order": {
    "recipient_email": "zach@hackclub.com",
    "tags": ["high-seas", "welcome-kit"],
    "idempotency_key": "hs-welcome-zach-2026",
    "user_facing_title": "Your High Seas Welcome Envelope!",
    "metadata": { "hs_id": "usr_zach123" }
  },
  "contents": [
    { "sku": "Sti/Example/1", "quantity": 3 }
  ]
}
```

`contents` is optional for template orders — the template defines the default items. If you include `contents`, those items are added on top of the template defaults.

### Creating a freeform order (from SKUs)

```
POST /api/v1/warehouse_orders
```

Same body structure, but `contents` is required — you need at least one item.

```json
{
  "address": { ... },
  "warehouse_order": {
    "recipient_email": "max@hackclub.com",
    "tags": ["boba-drops"],
    "idempotency_key": "boba-max-march-2026",
    "metadata": {}
  },
  "contents": [
    { "sku": "Five/Dollar/Bill", "quantity": 1 },
    { "sku": "Thoughtful/Postcard", "quantity": 1 }
  ]
}
```

**Warehouse order fields:**
| Field | Required | Notes |
|---|---|---|
| `address` | yes | top-level, same format as letters |
| `warehouse_order.recipient_email` | yes | used for shipping notifications |
| `warehouse_order.tags` | yes | array of strings, at least one. used for internal tracking and cost attribution |
| `warehouse_order.idempotency_key` | no | **use it. please.** |
| `warehouse_order.user_facing_title` | no | friendly name shown in recipient-facing contexts |
| `warehouse_order.metadata` | no | arbitrary JSON, same as letters |
| `contents` | template: no, freeform: yes | array of `{ "sku": "...", "quantity": N }` |

**Response (201):**
```json
{
  "warehouse_order": {
    "id": "pkg!abc123",
    "status": "dispatched",
    "tags": ["high-seas", "welcome-kit"],
    "address": { ... },
    "metadata": { "hs_id": "usr_zach123" },
    "recipient_email": "zach@hackclub.com",
    "dispatched_at": "2026-03-03T15:30:00Z",
    "mailed_at": null,
    "tracking_number": null,
    "carrier": null,
    "service": null,
    "weight": null,
    "contents_cost": "1.23",
    "labor_cost": "2.00",
    "postage_cost": null,
    "idempotency_key": "hs-welcome-zach-2026"
  }
}
```

**Order lifecycle:** `draft` → `dispatched` → `mailed` (or `canceled` / `errored`)

Tracking info (`tracking_number`, `carrier`, `service`) populates once the warehouse ships the package.

### Checking on an order

```
GET /api/v1/warehouse_orders/:id
```

`:id` is the order's public ID (e.g., `pkg!abc123`).

### Listing your orders

```
GET /api/v1/warehouse_orders
```

Returns all warehouse orders visible to your API key. Admins see all; regular keys see their own.

### Embedding a tracking widget

```
GET /packages/:id/embed
```

Public endpoint, no auth required. Returns an HTML page designed to be iframed:

```html
<iframe
  src="https://mail.hackclub.com/packages/pkg!abc123/embed"
  style="width: 100%; border: none; min-height: 200px;"
></iframe>
```

Shows order timeline, backorder info, tracking link, and contents. Only works for dispatched orders — draft orders show an error state. Frameable from any domain.

---

## Tags

Tags are how Theseus tracks what mail belongs to what program. Every letter queue assigns tags automatically; warehouse orders require at least one tag in the request.

```
GET /api/v1/tags
```
Returns all available tags.

```
GET /api/v1/tags/:tag_name
```
Returns aggregate stats (letter count, warehouse order count, costs) for a tag. Cached for 5 minutes; pass `?no_cache=true` to force-refresh.

```
GET /api/v1/tags/:tag_name/letters
```
Returns all letters with that tag.

---

## Errors

All errors return JSON with an `error` field and usually a `messages` array:

```json
{
  "error": "missing_parameter",
  "messages": ["param is missing or the value is empty: tags"]
}
```

Letter queue and warehouse order endpoints may return 422 instead of 400 for validation failures, with a slightly different shape:

```json
{
  "error": "Validation failed",
  "details": ["City can't be blank", "Postal code can't be blank"]
}
```

Idempotency collisions return 400. The response does **not** include the original resource — if you need the letter/order that was already created, you'll have to look it up separately.

```json
{
  "error": "idempotency_error",
  "messages": ["a record by that idempotency key already exists!"]
}
```

**Error reference:**

| Error | Status | Meaning |
|---|---|---|
| `invalid_auth` | 401 | API key is missing, invalid, or revoked |
| `not_authorized` | 403 | valid key, but you don't have permission for this action |
| `missing_parameter` | 400 | a required field is missing or empty |
| `validation_error` | 400 | something's wrong with the data (bad address, missing fields) |
| `Validation failed` | 422 | same as above, from letter queue and warehouse order endpoints |
| `idempotency_error` | 400 | you already sent a request with that idempotency key — **this is intentional protection, not a bug** |
| `resource_not_found` | 404 | the letter, order, queue, template, or SKU doesn't exist |

When writing error handling, match on the `error` field, not the status code — the same logical error can come back as 400 or 422 depending on the endpoint.

---

## Shipping and mailing concerns

Things that will cause problems if you ignore them:

**Address quality matters.** Bad addresses waste postage (USPS charges whether the letter arrives or not) and warehouse labor (someone packs a box that gets returned). If you have user-submitted addresses, validate them before sending to Theseus. At minimum: check that required fields aren't empty, that the country is a real ISO code, and that the postal code looks plausible for the country.

**International mail is more expensive and slower.** Domestic US mail is cheap and fast. International mail costs significantly more and can take weeks. If your program is sending high volumes internationally, talk to Nora about cost expectations.

**Blocked countries exist for warehouse orders.** Iran (IR), Palestine (PS), Cuba (CU), North Korea (KP), and Russia (RU) are blocked. The API will reject these. Letters are not hard-blocked by country but use judgment — mail to sanctioned countries may not arrive and may cause compliance issues.

**Postcards are not letters.** Instant Queues send postcards. Batch Queues send letters in envelopes. If your content is private, sensitive, or longer than what fits on a postcard, use a Batch Queue. Postcards are visible to anyone who handles them.

**Postage costs real money.** Every letter and package costs real postage. Instant Queue postcards buy postage the moment you call the API. Batch Queue letters buy postage when batched. Warehouse orders have contents cost + labor cost + postage cost. Don't send test requests to production. Don't build retry loops without idempotency keys.

**Don't get Hack Club in trouble with the Postal Service.** No spam. No unsolicited bulk mail to people who didn't opt in. No prohibited content. If you're unsure whether your use case is okay, ask.

---

## Public API (for end-user-facing apps)

The public API lets you build experiences where a person can see their own mail and packages. It uses separate API keys (`Public::APIKey`) and is scoped to a single public user.

```
GET /api/public/v1/me          — current user info
GET /api/public/v1/mail        — all mail (letters + packages), sorted newest first
GET /api/public/v1/letters     — letters addressed to this user
GET /api/public/v1/letters/:id — single letter
GET /api/public/v1/packages    — warehouse orders addressed to this user
GET /api/public/v1/packages/:id — single package (includes tracking link and contents)
```

Pass `?expand=events` on letter endpoints to include tracking events. Pass `?expand=path` to include API paths in responses.

Package responses include `tracking_link` (a clickable URL) and `contents` (list of items with SKU, name, and quantity). If the order is marked as a surprise, `contents` is empty.

---

## Expand system

Both APIs support `?expand=field1,field2` to opt into optional response fields. Known expansions:

- `label` — include label URLs on letter responses (requires PII-capable key)
- `path` — include API paths in public API responses
- `events` — include tracking events in public API letter responses

---

## Quick reference

| Action | Method | Endpoint |
|---|---|---|
| Submit letter to batch queue | POST | `/api/v1/letter_queues/:slug` |
| Submit letter to instant queue | POST | `/api/v1/letter_queues/instant/:slug` |
| Get a letter | GET | `/api/v1/letters/:id` |
| Create warehouse order (freeform) | POST | `/api/v1/warehouse_orders` |
| Create warehouse order (template) | POST | `/api/v1/warehouse_orders/from_template/:template_id` |
| Get a warehouse order | GET | `/api/v1/warehouse_orders/:id` |
| List warehouse orders | GET | `/api/v1/warehouse_orders` |
| List tags | GET | `/api/v1/tags` |
| Tag stats | GET | `/api/v1/tags/:tag_name` |
| Tag letters | GET | `/api/v1/tags/:tag_name/letters` |
| Tracking widget (public, no auth) | GET | `/packages/:id/embed` |
