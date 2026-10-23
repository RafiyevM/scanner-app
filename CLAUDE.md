# Scanner — Claude Code Instructions

Project entry point. Keep this file short; add detail to the imported documents.

## Required structure

- Application code lives under `Projects/`.
- Shared development resources live under `Root/`.
- Framework-required files (`CLAUDE.md`, `README.md`, `.gitignore`, `.claude/`)
  stay at the repository root.
- Create only folders that contain real content.

## Implementations

- **Flutter mobile app:** `Projects/MobileApp`
  - Auth: `lib/src/auth/`, `state/login_view_model.dart`, `ui/login_screen.dart`
  - Products: `models/product.dart`, `data/product_*`, `assets/products.json`
  - Scanner: QR + 1D barcode modes in `ui/scanner_screen.dart`
  - Tests: `test/`
- **Pure C# core:** `Projects/MobileApp.CSharp`
  - Library: `QRScanner.Core` (`net10.0`, no MAUI/Android/UI dependencies)
  - Tests: `QRScanner.Core.Tests` (console runner)
  - No Android app and no APK from this project
- **Backend:** `Projects/Backend/ProductApi`
  - C# minimal API + Npgsql
  - PostgreSQL schema/seed: `Root/Infrastructure/postgres/init/001_products.sql`

There is no .NET MAUI app and no Kotlin application code. The Flutter Android
host is Java (`android/app/src/main/java/.../MainActivity.java`). No React and no
direct PostgreSQL access from the mobile app.

## Domain

- Ten phone products, each with ID, name, description, color, quantity, barcode,
  and QR payload.
- Lookup matches product ID, barcode, or QR payload.
- In stock → product details.
- Product exists with quantity 0 → **Not in stock**, still showing details.
- No match → **No such product**.

## Architecture

@Root/Instructions/architecture.md

## Coding standards

@Root/Instructions/coding-standards.md

## Folder rules

@Root/Instructions/folder-structure.md

## Build and test

### Flutter

- Tests: `./Root/Scripts/test-flutter.sh`
- Build APK: `./Root/Scripts/build-flutter.sh`
- Install APK: `./Root/Scripts/install-flutter.sh`
- Logs: `./Root/Scripts/device-logs.sh`
- Documentation: `Root/Documentation/flutter-app.md`
- Requires: Flutter 3.47.7, JDK 21, Android SDK API 36
- Data source: remote PostgreSQL by default.
- Online access: `Root/Scripts/start-backend.sh` starts PostgreSQL, the API, and
  a public Cloudflare tunnel. Rebuild with
  `--dart-define=API_BASE_URL=https://<url>/` when the tunnel URL changes.
- LAN-only alternative: `--dart-define=API_BASE_URL=http://<your-mac-ip>:8080/`.
- USB fallback: `adb reverse tcp:8080 tcp:8080` with
  `--dart-define=API_BASE_URL=http://127.0.0.1:8080/`.
- Set `dataSource = 'local'` to use the bundled catalog.

### C# core

- Tests: `./Root/Scripts/test-csharp.sh`
- Build library: `./Root/Scripts/build-csharp.sh`
- Documentation: `Root/Documentation/csharp-core.md`
- Requires: .NET 10 SDK

### Backend

- Build: `dotnet build Projects/Backend/ProductApi/ProductApi.csproj`
- Run: see `Root/Documentation/postgresql-backend.md`
- Docker: `docker compose -f Root/Infrastructure/docker-compose.yml up -d --build`

## Rules

- Never commit secrets, API keys, keystores, or signing material.
- The backend credentials in documentation are local development values only.
- Use parameterized SQL; never concatenate user input into SQL.
- The app must not cache remote products: every scan queries the API so newly
  added depot products are recognized without rebuilding the app.
- Never invent an API endpoint, QR/barcode schema, or business rule. Unknown
  contract details stay configurable and documented as provisional.
- Keep both code implementations' parser/product logic pure and unit-tested.
- Keep the C# core free of MAUI, Android, and UI references.
- Prefer small, reversible changes and preserve working behavior.
- Do not add dependencies without a concrete need.
