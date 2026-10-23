# API Integration

## Data sources

| Mode | Flutter source | Data |
|---|---|---|
| `dataSource = 'local'` | `LocalProductRepository` | `assets/products.json` (10 phones) |
| `dataSource = 'remote'` | `RemoteProductRepository` | `ProductApi` → PostgreSQL |

**Current default:** `dataSource = 'remote'` with
`apiBaseUrl = 'http://127.0.0.1:8080/'`. The app sends every scan to the API; it
never connects directly to PostgreSQL.

The C# core exposes the same repository contracts with the same remote contract.

## Product endpoint

```http
GET {baseUrl}products/{code}
Accept: application/json
```

`{code}` may be a product ID, barcode, or QR payload. The API matches:

```sql
lower(id) = lower(@code)
OR barcode = @code
OR lower(qr_code) = lower(@code)
```

Successful response (`200`):

```json
{
  "id": "PHN-001",
  "name": "Aurora X1",
  "description": "6.4-inch OLED display, 128 GB storage, dual 50 MP camera, 5000 mAh battery.",
  "color": "Midnight Black",
  "quantity": 12,
  "barcode": "2000000000015",
  "qrCode": "{\"id\":\"PHN-001\",\"type\":\"phone\"}",
  "inStock": true
}
```

- `quantity > 0` → **Product found / In stock**
- `quantity == 0` → **Not in stock**, with the full product details
- `404` → **No such product**
- `401` / `403` → not authorized (reserved for future auth)
- `5xx` → server unavailable
- Timeout/offline → could not reach the server
- Malformed body → unexpected response

The C# core also treats `quantity == 0` as out of stock rather than a failure.

## Authentication endpoint

The app requires sign-in before scanning.

- Local demo mode (default): `test` / `test`.
- Remote mode: set `authMode = 'remote'` in `AppConfig`.

```http
POST {baseUrl}auth/login
Content-Type: application/json

{"username": "test", "password": "test"}
```

Successful response:

```json
{"token": "opaque-token"}
```

- `401` / `403` → incorrect credentials
- Other non-2xx → sign-in failed
- Timeout/offline → could not reach the server
- Malformed/missing token → unexpected response

Tokens are held in memory only. **The auth contract is provisional; the current
ProductApi does not implement it.**

## Configuration

`AppConfig` in `Projects/MobileApp/lib/main.dart`:

```dart
static const String authMode = 'local';     // or 'remote'
static const String dataSource = 'remote';  // or 'local'
static const String apiBaseUrl = 'http://127.0.0.1:8080/';
```

The URL must end with `/`.

| Environment | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:<port>/` |
| USB device with `adb reverse` | `http://127.0.0.1:<port>/` |
| Wi-Fi device | `http://<host-lan-ip>:<port>/` |

USB development against the local API:

```bash
adb reverse tcp:8080 tcp:8080
```

## Backend endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Health check |
| `GET` | `/products` | List all products |
| `GET` | `/products/{code}` | Lookup by ID, barcode, or QR payload |
| `POST` | `/products` | Add or update a product |

New products added with `POST /products` (or directly in PostgreSQL) are
recognized on the next scan; the app keeps no product cache and sends a fresh
request for every scan.

See `Root/Documentation/postgresql-backend.md`.

## Network security

The generated Android manifest enables cleartext HTTP for local development.
Remove that for production and use HTTPS.

## Timeouts

The Flutter remote repositories and the C# core use a 20-second timeout.

## Logging

No HTTP body logging is enabled. Never log credentials, tokens, decoded payloads,
or product data.

## PostgreSQL

PostgreSQL is accessed only by the ProductApi, never directly by the mobile app.
The schema and 10-product seed are in
`Root/Infrastructure/postgres/init/001_products.sql`.
