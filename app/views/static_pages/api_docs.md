# API docs!
hey! i'm glad you're here. let's send some stuff to some people!!

**for the robots and their handlers:**

[append .md](/back_office/api-docs.md) to this URL or click this handy button to get an AI-slop friendly version of these docs.

the ones you're reading right now are for people to read with their eyes and understand with their brains.

%AI-COPY-BUTTON%

### authorization (the technical kind):

pretty easy. you'll need a Theseus back office API key - if you don't have one you can %API-KEY-BUTTON%

once you have it, just pass it in the `Authorization` header of your requests like so:

```
Authorization: Bearer th_apk_live_alskfjsdkfjksdjhf
```

### authorization (the other kind):
if you're planning on using the warehouse, talk to Zach/Nora first!

if you're sending letters, don't get us in trouble with the Postal Service.

if you're at all unsure whether your use case for the Theseus API is okay, please poke me!

it probably is, but continued access to this system is contingent on good behavior.

# Sending Mail
_(mail as in shipping vs. mailing, letters and flats and whatnot, we'll get to packages later.)_
## Two paths are before you.
**Instant Queues** and **Batch Queues**. both are powerful primitives for bringing the joy of mail into your program!

which one you'll use depends on what you're trying to do.

let's start with the popular one,
### Batch Queues:

Batch Queues are the simplest way to manage sending out large quantities of mail to Hack Clubbers.

your platform sends requests for letters to Theseus, and then when you're ready to send a bunch of letters,
you can snap the pending letters in the queue into a Batch and generate labels for it.

the API side of this is just the "send requests for letters" part — once you've queued up your letters,
you (or Nora) will batch them up and generate labels in the back office.

#### queuing a letter:
```
POST /api/v1/letter_queues/:queue_slug
```

your queue has a slug (its name, but URL-safe). you'll get this when your queue is set up.

the body of your request should look like this:
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
  "idempotency_key": "fiona-welcome-letter-2026",
  "metadata": {
    "source": "onboarding",
    "wave": 3
  }
}
```

**the fields:**
- `address` — required. the recipient's mailing address. we'll do our best to figure out country names and state abbreviations, but ISO 3166 alpha-2 country codes and standard state abbreviations are safest.
- `recipient_email` — the recipient's email. not required, but very helpful for us to have.
- `rubber_stamps` — optional. custom text that gets printed on the letter. use this for personalized messages!
- `idempotency_key` — optional but **strongly recommended**. more on this in a sec.
- `metadata` — optional. a JSON object of whatever you want! this is yours — Theseus will store it and give it back to you on the letter object, and you can use it in your custom letter templates. put your internal IDs, feature flags, custom messages, whatever you need here.

**the response** (201 Created):
```json
{
  "id": "ltr_abc123",
  "sender": "usr_def456",
  "status": "queued",
  "tags": ["your-project"],
  "return_address": { "line_1": "...", "city": "...", "..." : "..." },
  "address": { "first_name": "Fiona", "last_name": "Hackworth" },
  "rubber_stamps": "hey Fiona! hope you like stickers!",
  "metadata": { "source": "onboarding", "wave": 3 }
}
```

that letter is now sitting in your queue, waiting for someone to batch it up! the letter's `status` will be `queued` until it gets snapped into a batch, at which point it becomes `pending`.

a letter's lifecycle goes: `queued` → `pending` → `printed` → `mailed` → `received`

#### checking on a letter:
```
GET /api/v1/letters/:id
```

returns the same letter object as above. you can use this to poll for status changes if you want to track a letter through the pipeline.

---

### Instant Queues:

Instant Queues are the cool, impatient sibling of Batch Queues. instead of waiting for a human to come along and batch things up, an Instant Queue prints your mail as a postcard and drops it straight into the outbox — buys postage (if it's set up for indicia), the whole deal, all in one request.

this is for transactional mail: "your project was marked as awesome! <picture of the project>", things like that.

#### sending a letter instantly:
```
POST /api/v1/letter_queues/instant/:queue_slug
```

same body as Batch Queues:
```json
{
  "address": {
    "first_name": "Kai",
    "last_name": "Leidecker",
    "line_1": "456 Oak Ave",
    "city": "Burlington",
    "state": "VT",
    "postal_code": "05401",
    "country": "US"
  },
  "recipient_email": "kai@hackclub.com",
  "rubber_stamps": "your mass of stickers is enclosed.",
  "idempotency_key": "kai-sticker-drop-march-2026",
  "metadata": { "program": "sticker-drop", "batch_num": 42 }
}
```

**the response** (201 Created) is the same letter object, but the status will be `pending` (not `queued`) and if the queue uses indicia, the postage will already be purchased. the postcard is printed and in the outbox.

#### the tradeoffs:
Instant Queues are a fundamentally different primitive from Batch Queues. when you submit a letter to an Instant Queue, it gets printed as a postcard and dropped straight into the outbox — no batching, no label generation, no human in the loop. this means:
- **they're postcards.** Instant Queues print postcards, not letters in envelopes. if your content doesn't fit on a postcard, you want a Batch Queue.
- **they're slower per-request** than Batch Queue requests. the request does real work (printing, postage) and you should expect it to take a few seconds.
- **errors are louder.** if something breaks, you'll get an error on the spot. with Batch Queues, that stuff happens later when a human is watching.
- **they cost money immediately.** if your queue is set up with indicia postage, the postage charge goes through the moment you make the request.

for most "send a bunch of letters to a bunch of people" use cases, Batch Queues are the move. Instant Queues shine when you need a postcard out the door right now, no waiting.

---

## a sermon on idempotency keys

both letter queues and warehouse orders support an `idempotency_key` field.

**please use them.**

an idempotency key is a unique string you make up that represents "this specific intent to send this specific thing." if you accidentally send the same request twice (your code retried, your queue double-fired, gremlins, whatever), Theseus will see the duplicate idempotency key and reject the second request instead of creating a duplicate letter.

```json
{
  "idempotency_key": "onboarding-fiona-hackworth-2026-03"
}
```

the key just needs to be unique within your usage. some good patterns:
- `"{program}_{env}-{user_id}-{action}"` — e.g. `"high-seas_prod-usr_abc123-welcome-letter"`
- whatever your system already uses to deduplicate work

if you send a request with a duplicate idempotency key, you'll get back:
```json
{
  "error": "idempotency_error",
  "messages": ["a record by that idempotency key already exists!"]
}
```

this is a 400, not a 500. it's Theseus looking out for you.

without idempotency keys, there's nothing stopping a retry from sending someone two identical letters. that's a waste of postage at best and confusing at worst. be kind to future-you: use idempotency keys.

---

# The Warehouse
_(packages! parcels! the big stuff!)_

the warehouse API lets you create shipping orders that get fulfilled by our warehouse partner. you send us what to ship and where, and it goes out.

there are two ways to create a warehouse order: **from a template** or **freeform from SKUs**.

## from a template:
templates are pre-configured bundles of items. if you're always sending the same kit (a welcome pack, a prize bundle, etc.), ask Nora to set one up and you'll get a template ID.

```
POST /api/v1/warehouse_orders/from_template/:template_id
```

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
    "tags": ["high-seas", "welcome-envelope"],
    "idempotency_key": "hs-welcome-zach-2026",
    "user_facing_title": "Your High Seas Welcome Envelope!",
    "metadata": { "hs_id": "usr_zach123" }
  },
  "contents": [
    { "sku": "Sti/Example/1", "quantity": 3 }
  ]
}
```

the `contents` array is optional here — the template already defines what goes in the box. but if you want to add _extra_ items on top of the template's defaults, you can include them in `contents`.

## freeform (from SKUs):
if you don't have a template, you can build an order from scratch using SKU codes.

```
POST /api/v1/warehouse_orders
```

```json
{
  "address": {
    "first_name": "Max",
    "last_name": "Wofford",
    "line_1": "1 Infinite Loop",
    "city": "Cupertino",
    "state": "CA",
    "postal_code": "95014",
    "country": "US"
  },
  "warehouse_order": {
    "recipient_email": "max@hackclub.com",
    "tags": ["boba-drops"],
    "idempotency_key": "boba-max@hackclub.com-march-2026",
    "metadata": {}
  },
  "contents": [
    { "sku": "Five/Dollar/Bill", "quantity": 1 },
    { "sku": "Thoughtful/Postcard", "quantity": 1 }
  ]
}
```

`contents` is required for freeform orders — you need at least one item.

**required fields for all warehouse orders:**
- `address` — where it's going.
- `warehouse_order.recipient_email` — who it's for. we use this for shipping notifications.
- `warehouse_order.tags` — at least one tag. this is how we categorize and track shipments internally.

**optional fields:**
- `warehouse_order.idempotency_key` — you know the drill. use it. please.
- `warehouse_order.user_facing_title` — a friendly name for the shipment that might show up in recipient-facing contexts.
- `warehouse_order.metadata` — same as with letters, a JSON object that's all yours.
- `contents` — additional SKU items (required for freeform, optional for template orders).

**the response** (201 Created):
```json
{
  "warehouse_order": {
    "id": "pkg_abc123",
    "status": "dispatched",
    "tags": ["high-seas", "welcome-kit"],
    "address": { "first_name": "Zach", "last_name": "Latta" },
    "metadata": { "hs_id": "usr_zach123" },
    "recipient_email": "zach@hackclub.com",
    "dispatched_at": "2026-03-03T15:30:00Z",
    "idempotency_key": "hs-welcome-zach-2026"
  }
}
```

the order is created and immediately dispatched to the warehouse. its status will update as it moves through fulfillment:
`draft` → `dispatched` → `mailed`

(there's also `canceled` and `errored` but let's hope you don't see those.)

#### checking on an order:
```
GET /api/v1/warehouse_orders/:id
```

once the order ships, `tracking_number`, `carrier`, and `service` will be populated in the response. you can use those to track the package.

#### listing your orders:
```
GET /api/v1/warehouse_orders
```

returns all warehouse orders visible to your API key.

#### embedding a tracking widget:

want to show your recipients their order status without sending them to a separate page? we've got an embeddable tracking widget you can drop into an iframe.

```
GET /packages/:id/embed
```

where `:id` is the order's ID (e.g. `pkg_abc123`). this is a public endpoint — no API key needed.

the widget is a self-contained HTML page designed to be iframed. it shows:
- **order timeline:** Order Placed → Sent to Warehouse → Shipped, with dates as they become available.
- **backorder info:** if any items are out of stock, the widget shows which ones and whether more are on the way.
- **tracking info:** once the order ships, the carrier and a clickable tracking number show up.
- **contents:** a list of what's in the box (unless you've marked the order as a surprise).

embed it like this:
```html
<iframe
  src="https://theseus.hackclub.com/packages/pkg_abc123/embed"
  style="width: 100%; border: none; min-height: 200px;"
></iframe>
```

a few things to know:
- **draft orders return an error state.** if the order hasn't been dispatched yet, the widget will show "Order not found or not ready yet" — so don't embed it until the order is dispatched.
- **no auth required.** the embed is public. anyone with the order ID can see it. this is by design — it's meant for recipient-facing contexts.
- **frameable from anywhere.** the CSP is wide open on this endpoint, so you can iframe it from any domain.

---

**a note on countries:** we do our best to parse whatever you throw at us ("United States", "US", "USA", "us", etc.) but the safest bet is always ISO 3166 alpha-2 codes. same goes for states — "Vermont" and "VT" both work, but abbreviations are less likely to surprise you.

**a note on errors:** if something goes wrong, you'll get back a JSON object with an `error` field and usually a `messages` array. common errors:
- `invalid_auth` (401) — your API key is missing or dead.
- `not_authorized` (403) — your API key is valid but doesn't have permission to do that.
- `missing_parameter` (400) — you forgot a required field.
- `validation_error` (400) — something's wrong with your data (bad address, etc.).
- `idempotency_error` (400) — you already sent something with that idempotency key. this is a feature, not a bug!
- `resource_not_found` (404) — couldn't find that queue, letter, order, template, or SKU.

---

~your pal, Nora