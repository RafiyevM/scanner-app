# Architecture Rules

The repository contains a Flutter mobile app, a pure C# core, and a C# product
API backed by PostgreSQL. There is no MAUI app.

## Flutter layers

- `lib/src/auth/` — auth contract, local demo auth, provisional remote auth.
- `lib/src/models/` — `Product`.
- `lib/src/qr/` — pure parser/validator.
- `lib/src/data/` — `ProductRepository`, local asset and remote HTTP sources.
- `lib/src/state/` — `ScanUiState`, `ScannerViewModel`, `LoginViewModel`.
- `lib/src/services/` — sound effects.
- `lib/src/ui/` — login, Home with Scan button, scanner (QR/barcode modes),
  result rendering, language/sound controls.
- `lib/l10n/` — English, Azerbaijani, Russian strings.
- `assets/images/phones/`, `assets/sounds/` — product art and sound effects.

## C# core layers

- `QRScanner.Core/Qr` — pure parser.
- `QRScanner.Core/Models` — `Product`, `LookupResult`.
- `QRScanner.Core/Data` — product store/repository contracts and remote source.
- `QRScanner.Core/State` — `ScanUiState`, `ScannerViewModel`.
- `QRScanner.Core.Tests` — console test runner.

The C# core is a library and test runner; it has no UI, camera, MAUI, or APK.

## Backend

- `Projects/Backend/ProductApi` — ASP.NET Core minimal API.
- `Root/Infrastructure/postgres/init/001_products.sql` — schema and seed.
- `Root/Infrastructure/docker-compose.yml` — PostgreSQL + API.

The API reads the connection string from configuration/environment and uses
parameterized Npgsql queries.

## Product lookup

A scan (QR or barcode) produces a code. A product matches when its ID, barcode, or
QR payload equals that code (ID/QR case-insensitive, barcode exact).

- Match with `quantity > 0` → success with all product fields.
- Match with `quantity == 0` → out of stock, still showing product fields.
- No match → not found.
- Transport/parse failure → retryable error.
- Remote lookups are never cached: every scan queries the API so newly added
  depot products are recognized immediately.

## Scan modes

The scanner supports:

- **QR:** `BarcodeFormat.qrCode`.
- **Barcode:** EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, ITF,
  Codabar.

Changing the mode resets the scan state and recreates the scanner controller.

## Authentication and navigation

- The app starts at login.
- Successful sign-in creates an in-memory `AuthSession` and shows Home.
- The camera starts only after the user taps “Scan code” on Home.
- Back from the scanner returns to Home; sign-out returns to login.
- Local demo credentials are `test` / `test`; remote auth is provisional.
- Passwords and tokens are never persisted or logged.
- All user-facing text is localized in English, Azerbaijani, and Russian.
- One cashier-style scanner beep plays per scan; it can be muted.
- The camera stops after a result; scanning restarts only from Home.

## State

Use explicit state types:

- scanning
- loading
- success (in stock)
- out of stock
- not found
- invalid
- error

Same-payload suppression applies until the code changes or the user resets.
Scanning is disabled while loading, success, out-of-stock, or error.

## Configuration

- Flutter: `AppConfig` selects auth mode, local/remote data, and the base URL.
- Backend: `ConnectionStrings:Products` / `CONNECTIONSTRINGS__PRODUCTS`.
- No production secrets are committed.
