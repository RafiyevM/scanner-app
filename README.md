# Scanner

Android app for scanning **QR codes and 1D barcodes** to look up phone products.

Each product has an ID, name, description, color, depot stock quantity, and
barcode, plus a QR payload used for scanning. The app shows the product details
and stock state after a scan, including a dedicated **Not in stock** state.

## Stack

| Part | Technology |
|---|---|
| Mobile app | Flutter 3.47.7 / Dart |
| Scanner | `mobile_scanner` 6.0.11 (QR + EAN/UPC/Code 128/Code 39/Code 93/ITF/Codabar) |
| Login | Local demo gate (`test` / `test`) + provisional remote auth seam |
| Local catalog | `assets/products.json` |
| C# core | .NET 10 class library (`net10.0`) |
| Backend | C# minimal API + PostgreSQL (`Npgsql`) |
| Languages | English, Azərbaycan dili, Русский |
| Phone recognition | Phone mode photographs a phone; the backend identifies it with Google Gemini (needs `GEMINI_API_KEY`) |
| Sound effect | One cashier-style scanner beep when a code is scanned |
| Product images | Local SVG illustrations for the 10 phones |

No Kotlin application code, MAUI, React, or direct PostgreSQL access from the
mobile app. Flutter’s Android host is generated in Java.

## Status

- Flutter tests: **68/68 passing**
- `flutter analyze`: **no issues**
- C# core tests: **45/45 passing**
- PostgreSQL API: verified locally (`/health`, `/products/{code}`, `POST /products`)
- App data source: **PostgreSQL via ProductApi** (`dataSource = 'remote'`)
- Online access: public HTTPS tunnel via `Root/Scripts/start-backend.sh`; works
  without a USB cable
- New depot products are recognized on the next scan — no app rebuild needed
- Flutter debug APK built
- Device install blocked by the device’s install permission (`INSTALL_FAILED_USER_RESTRICTED`); allow “Install via USB” and confirm the on-device prompt

## Login

The scanner is gated by a sign-in screen.

- Username: `test`
- Password: `test`

Local authentication is a demonstration gate, not production security. Remote
auth is a provisional `POST {baseUrl}/auth/login` contract. Passwords and tokens
are never stored or logged.

After sign-in the app shows a Home screen. The camera is **not started until the
user taps “Scan code”**. The app then scans, plays one cashier-style scanner beep, looks up the
product, and shows the result. The camera stops after the result; tap
“Scan another code” to return Home and start a new scan.

Languages can be switched from the globe icon on the login, Home, and scanner
screens: English, Azerbaijani, and Russian.

## Scan modes

Choose **QR** or **Barcode** above the camera.

- **QR:** QR codes
- **Barcode:** EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93, ITF,
  Codabar

A scan can match a product by **ID**, **barcode**, or **QR payload**.

## Products

Ten demo phone products are included. Products with quantity `0` show
**Not in stock**; unknown codes show **No such product**.

Full code table: `Root/Documentation/product-codes.md`.

Examples:

| Code | Result |
|---|---|
| `PHN-001` or `2000000000015` | Aurora X1, 12 in stock |
| `PHN-003` or `2000000000039` | Pulse 7, not in stock |
| `UNKNOWN-404` | No such product |

## Repository layout

```text
Projects/
  MobileApp/                       Flutter Android app
    lib/
      l10n/                        English/Azerbaijani/Russian ARB + generated code
      src/
        auth/
        models/
        qr/
        data/
        services/                  Sound effects
        state/
        ui/                        Login, Home, Scanner, results
    test/
    assets/products.json
    assets/images/phones/          10 phone SVG illustrations
    assets/sounds/                 Scan/result WAV sounds
    android/
  MobileApp.CSharp/                Pure C# core (no Android UI)
    QRScanner.Core/
    QRScanner.Core.Tests/
    QRScanner.Core.slnx
  Backend/ProductApi/              C# minimal API + Npgsql
Root/
  Documentation/
  Infrastructure/                  Docker Compose + PostgreSQL init SQL
  Instructions/
  Scripts/
  Skills/
CLAUDE.md
README.md
```

Build outputs are ignored by Git. The Android SDK, JDK 21, and Flutter live outside the repository at `~/toolchains/`.

## Prerequisites

- Flutter 3.47.7
- JDK 21
- Android SDK: platform-tools, API 36 platform, build-tools 36.0.0
- .NET 10 SDK
- PostgreSQL 16+ or Docker (for the backend)

## Flutter app

```bash
./Root/Scripts/test-flutter.sh
```

```bash
./Root/Scripts/build-flutter.sh
```

```bash
./Root/Scripts/install-flutter.sh
```

APK:

```text
Projects/MobileApp/build/app/outputs/flutter-apk/app-debug.apk
```

If the device rejects ADB installs, enable **Developer options → Install via USB**
and accept the on-device install prompt. Without it, `adb install` returns
`INSTALL_FAILED_USER_RESTRICTED`.

The app calls the ProductApi over the network — no USB cable required.

```bash
./Root/Scripts/start-backend.sh
```

That starts PostgreSQL, the API on `0.0.0.0:8080`, and a public Cloudflare quick
tunnel, then prints an HTTPS URL such as:

```text
https://<random-name>.trycloudflare.com
```

The app default is compiled with that URL. If the tunnel URL changes (quick
tunnels are temporary), rebuild with the new one:

```bash
cd Projects/MobileApp && flutter build apk --dart-define=API_BASE_URL=https://<new-url>/
```

For local Wi-Fi only (no tunnel), use the Mac’s LAN address instead:

```bash
--dart-define=API_BASE_URL=http://<your-mac-ip>:8080/
```

Every scan calls `GET /products/{code}`; the API queries PostgreSQL and returns
the product, out-of-stock status, or `404`. New products added with
`POST /products` or directly in PostgreSQL are recognized on the next scan — no
app rebuild is needed. To use the bundled catalog instead, set
`dataSource = 'local'` in `AppConfig`.

Full details: `Root/Documentation/flutter-app.md`.

## PostgreSQL backend

Local Postgres.app setup:

```bash
open -a Postgres
```

Create the database and apply the seed once:

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql -d postgres -c "CREATE ROLE scanner LOGIN PASSWORD 'scanner';"
```

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql -d postgres -c "CREATE DATABASE scanner OWNER scanner;"
```

```bash
/Applications/Postgres.app/Contents/Versions/latest/bin/psql "postgresql://scanner:scanner@localhost:5432/scanner" -f Root/Infrastructure/postgres/init/001_products.sql
```

Run the API:

```bash
cd Projects/Backend/ProductApi
ConnectionStrings__Products='Host=localhost;Port=5432;Database=scanner;Username=scanner;Password=scanner' ASPNETCORE_URLS='http://127.0.0.1:8080' dotnet run
```

Docker alternative:

```bash
docker compose -f Root/Infrastructure/docker-compose.yml up -d --build
```

Point the app at it by setting `dataSource = 'remote'` and
`apiBaseUrl = 'http://127.0.0.1:8080/'` in `AppConfig`, then:

```bash
adb reverse tcp:8080 tcp:8080
```

Full details: `Root/Documentation/postgresql-backend.md`.

## C# core

```bash
./Root/Scripts/test-csharp.sh
```

```bash
./Root/Scripts/build-csharp.sh
```

The C# core is a library and test runner; it does not produce an APK.

## Security

- No secrets, tokens, or signing material are committed.
- Backend credentials are local development values; change them for production.
- The API has no authentication yet; do not expose it publicly.
- Release builds should use HTTPS.
- Decoded content is never opened automatically and is not logged.
