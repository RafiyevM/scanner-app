# PostgreSQL Backend

The product catalog can be stored in PostgreSQL and served by the C# Product API.
The Flutter app uses the same 10 products locally when `dataSource = 'local'`.

## Architecture

```mermaid
flowchart LR
    APP[Flutter Scanner] -->|GET /products/{code}| API[ProductApi .NET 10]
    API -->|Npgsql| DB[(PostgreSQL)]
    APP -.->|local mode| ASSET[assets/products.json]
```

## Projects

```text
Projects/Backend/ProductApi/
├── ProductApi.csproj
├── Program.cs              Minimal API
├── Product.cs              Product DTO
├── Dockerfile
└── appsettings.json

Root/Infrastructure/
├── docker-compose.yml
└── postgres/init/001_products.sql
```

## Schema

```sql
CREATE TABLE products (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    description text NOT NULL,
    color       text NOT NULL,
    quantity    integer NOT NULL CHECK (quantity >= 0),
    barcode     text NOT NULL UNIQUE,
    qr_code     text NOT NULL UNIQUE
);
```

The seed inserts the 10 products listed in `product-codes.md`.

## Run with Docker

```bash
docker compose -f Root/Infrastructure/docker-compose.yml up -d --build
```

This starts PostgreSQL on `5432` and the API on `8080`. The development password
defaults to `scanner`; override it with `POSTGRES_PASSWORD`.

## Run with Postgres.app

The local setup used during development:

```bash
open -a Postgres
```

Create the role and database once:

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql -d postgres -c "CREATE ROLE scanner LOGIN PASSWORD 'scanner';"
```

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql -d postgres -c "CREATE DATABASE scanner OWNER scanner;"
```

Apply the schema and seed:

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql "postgresql://scanner:scanner@localhost:5432/scanner" -f Root/Infrastructure/postgres/init/001_products.sql
```

Run the API:

```bash
cd Projects/Backend/ProductApi
ConnectionStrings__Products='Host=localhost;Port=5432;Database=scanner;Username=scanner;Password=scanner' ASPNETCORE_URLS='http://127.0.0.1:8080' dotnet run
```

## Endpoints

| Method | Path | Result |
|---|---|---|
| `GET` | `/health` | `{"status":"ok"}` |
| `GET` | `/products` | All products |
| `GET` | `/products/{code}` | Product by id, barcode, or QR payload; `404` if none |
| `POST` | `/products` | Add or update a product immediately |
| `POST` | `/products/register` | Add a product from a scanned code; the server creates the ID |
| `POST` | `/identify` | Identify a phone from a JPEG photo and match it to the depot |

### Add a product from the camera

When the app scans a code that is not in the depot it shows **Add to depot**. The
user enters a name (description, color and quantity are optional) and the app
sends:

```bash
curl -X POST http://127.0.0.1:8080/products/register \
  -H 'Content-Type: application/json' \
  -d '{"code":"2888888888888","name":"New Phone","color":"Green","quantity":3}'
```

The server stores the scanned code as the barcode, creates the next ID
(`PHN-011`, `PHN-012`, ...) and a QR payload, and returns `201`. A code that
already exists returns `409` and is never overwritten. Blank names, negative
quantities and control characters return `400`.

### Add a new product

```bash
curl -X POST http://127.0.0.1:8080/products \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "PHN-011",
    "name": "Aurora X2",
    "description": "6.6-inch OLED, 256 GB, 108 MP camera.",
    "color": "Midnight Blue",
    "quantity": 5,
    "barcode": "2000000000114",
    "qrCode": "{\"id\":\"PHN-011\",\"type\":\"phone\"}"
  }'
```

The app queries PostgreSQL on **every scan** with no product cache, so a newly
added product is recognized immediately. No app rebuild or reinstall is needed.
Set `quantity: 0` to make it show **Not in stock**.

Example:

```bash
curl http://127.0.0.1:8080/products/PHN-001
```

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

Out-of-stock products are returned with `quantity: 0` and `inStock: false`; the
app renders the **Not in stock** state. Unknown codes return `404`, which the app
maps to **No such product**.

## Phone recognition (`POST /identify`)

The app's **Phone** mode photographs a phone and the backend asks **Google
Gemini** which model it is, then looks for a depot product with the same name.

Get a key from Google AI Studio (https://aistudio.google.com/apikey). Set it only
in the terminal that starts the API. It is read from the environment, sent to
Google in an `x-goog-api-key` header (never in the URL), and never stored in the
repository:

```bash
GEMINI_API_KEY=<your key> ./Root/Scripts/start-backend.sh
```

or, running the API directly:

```bash
GEMINI_API_KEY=<your key> dotnet run
```

| Variable | Default | Purpose |
|---|---|---|
| `GEMINI_API_KEY` | none | Required. Without it `/identify` returns `503` and the app says recognition is not set up |
| `GEMINI_MODEL` | `gemini-3.5-flash` | Gemini model name; use any vision-capable model |
| `GEMINI_API_BASE` | `https://generativelanguage.googleapis.com/v1beta` | Service base URL (override only for testing) |

Request: `{"image":"<base64 JPEG, at most 4 MB>"}`. Response:
`{"isPhone":true,"brand":"Apple","model":"iPhone 14","confidence":0.93,"matches":[...]}`.

Errors: `400` bad image, `502` Gemini failed, blocked the image or answered
unusably, `503` no key, `504` timeout.

Matching is **strict**: the depot product's name must equal the identified model
(letters and digits only, case-insensitive), so an iPhone 14 Pro is never reported
as in stock because an iPhone 14 is. Name depot products by their exact model,
for example `iPhone 14`. The demo products use made-up names and will not match.

Each photo is sent to Google. Do not point the camera at people or private
documents, and check the Gemini API terms and pricing for your key (free-tier
keys may use submitted content to improve Google products).

## Online access without a USB cable

Quickest option — starts PostgreSQL, the API on `0.0.0.0:8080`, and a public
Cloudflare quick tunnel:

```bash
./Root/Scripts/start-backend.sh
```

It prints an HTTPS URL like
`https://<random-name>.trycloudflare.com`. The app reads its API URL from the
`API_BASE_URL` build define, so rebuild if the tunnel URL changed:

```bash
cd Projects/MobileApp
flutter build apk --dart-define=API_BASE_URL=https://<random-name>.trycloudflare.com/
```

Quick-tunnel URLs are temporary and change when the tunnel restarts. For a stable
URL, use a named Cloudflare tunnel or deploy the API to a host of your choice.

LAN-only alternative (phone on the same Wi-Fi):

```bash
flutter build apk --dart-define=API_BASE_URL=http://192.168.0.23:8080/
```

## The Flutter app uses PostgreSQL

`AppConfig` in `Projects/MobileApp/lib/main.dart` is already set to:

```dart
static const String dataSource = 'remote';
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://<tunnel>.trycloudflare.com/',
);
```

For a USB device, forward the API port and build with the loopback URL:

```bash
adb reverse tcp:8080 tcp:8080
```

```bash
flutter build apk --dart-define=API_BASE_URL=http://127.0.0.1:8080/
```

Then install:

```bash
./Root/Scripts/build-flutter.sh
./Root/Scripts/install-flutter.sh
```

For an emulator, use `http://10.0.2.2:8080/` instead. To use the bundled catalog
without the backend, set `dataSource = 'local'`.

## Security

- The credentials above are local development values. Do not reuse them in
  production.
- No production secrets are committed. Use environment variables or a secret
  manager.
- The API currently has no authentication; add token validation before exposing
  it outside a trusted development network.
- Always use parameterized SQL (the API does).
