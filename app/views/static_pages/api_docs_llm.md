# Theseus API Documentation (LLM-friendly)

This is a structured reference for the Theseus mail and warehouse API.

## Authentication

All API requests require an API key passed via the `Authorization` header:

```
Authorization: Bearer YOUR_API_KEY
```

## Base URL

```
/api/v1
```

## Endpoints

### Letters

- `GET /api/v1/letters` - List letters
- `POST /api/v1/letters` - Create a letter
- `GET /api/v1/letters/:id` - Show a letter
- `PATCH /api/v1/letters/:id` - Update a letter
- `DELETE /api/v1/letters/:id` - Delete a letter
- `POST /api/v1/letters/:id/mark_printed` - Mark a letter as printed
- `POST /api/v1/letters/:id/mark_mailed` - Mark a letter as mailed

### Letter Queues

- `GET /api/v1/letter_queues` - List letter queues
- `POST /api/v1/letter_queues` - Create a letter queue
- `GET /api/v1/letter_queues/:id` - Show a letter queue
- `PATCH /api/v1/letter_queues/:id` - Update a letter queue
- `DELETE /api/v1/letter_queues/:id` - Delete a letter queue
- `POST /api/v1/letter_queues/instant/:id` - Create an instant letter
- `GET /api/v1/letter_queues/instant/:id/queued` - Show queued instant letter
- `POST /api/v1/letter_queues/:id` - Create a letter from queue

### Tags

- `GET /api/v1/tags` - List tags
- `GET /api/v1/tags/:id` - Show a tag
- `GET /api/v1/tags/:id/letters` - List letters for a tag

### User

- `GET /api/v1/user` - Show current user
- `POST /api/v1/user` - Create user
- `PATCH /api/v1/user` - Update current user
- `DELETE /api/v1/user` - Delete current user

### Warehouse Orders

- `GET /api/v1/warehouse_orders` - List warehouse orders
- `GET /api/v1/warehouse_orders/:id` - Show a warehouse order
- `POST /api/v1/warehouse_orders` - Create a warehouse order
- `POST /api/v1/warehouse_orders/from_template/:template_id` - Create from template

### QZ Tray

- `GET /api/v1/qz_tray/cert` - Get QZ Tray certificate
- `POST /api/v1/qz_tray/sign` - Sign QZ Tray request

### Public API (no auth required)

- `GET /api/public/v1/me` - Current user info
- `GET /api/public/v1/letters` - List letters
- `GET /api/public/v1/letters/:id` - Show a letter
- `GET /api/public/v1/packages` - List packages
- `GET /api/public/v1/packages/:id` - Show a package
- `GET /api/public/v1/mail` - List mail
- `GET /api/public/v1/lsv` - List LSVs
- `GET /api/public/v1/lsv/:slug/:id` - Show an LSV