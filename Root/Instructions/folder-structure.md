# Folder Structure Rules

## Top level

- `Projects/` — application and service code.
- `Root/` — development resources and infrastructure.
- Root files such as `CLAUDE.md`, `README.md`, `.gitignore`, and `.claude/` remain
  at the repository root because the toolchain requires them there.

## Projects/

- `MobileApp/` — the Flutter Android application.
  - `lib/src/auth/` — sign-in.
  - `lib/src/models/` — `Product`.
  - `lib/src/qr/` — QR/barcode content parsing.
  - `lib/src/data/` — product repositories.
  - `lib/src/state/` — login and scanner view models.
  - `lib/src/services/` — sound effects.
  - `lib/src/ui/` — login, Home, scanner, result panel, language/sound controls.
  - `lib/l10n/` — English/Azerbaijani/Russian ARB and generated code.
  - `test/` — unit and widget tests.
  - `assets/products.json` — local catalog.
  - `assets/images/phones/` — product illustrations.
  - `assets/sounds/` — the single scan beep audio.
  - `android/` — generated Flutter Android project.
- `MobileApp.CSharp/` — the pure C# core.
  - `QRScanner.Core/` — parser, `Product`, repositories, state.
  - `QRScanner.Core.Tests/` — console test runner.
  - `QRScanner.Core.slnx`.
  - No MAUI project and no Android app.
- `Backend/ProductApi/` — C# minimal API using Npgsql.
- `APIs/`, `Shared/`, `Tests/` — create only when real code exists.

## Root/

- `Skills/` — canonical Claude Code skills.
- `Arguments/` — reusable task prompts, only when reused.
- `Instructions/` — architecture, coding, and structure rules.
- `Configuration/` — safe templates only; no secrets.
- `Scripts/` — build, install, log, and test helpers.
- `Documentation/` — architecture, API, QR/barcode, product codes, backend,
  testing, and app guides.
- `Infrastructure/` — Docker Compose and PostgreSQL initialization.
- `Tools/` — shared utilities, only when needed.

## Claude Code discovery

- Project skills live at `.claude/skills/<name>/SKILL.md` (symlinked from
  `Root/Skills/<name>/`).
- `CLAUDE.md` references documents under `Root/` with `@path` imports.

## Stack boundary

- Flutter/Dart is the mobile app.
- C# is used for the pure core and the product API.
- PostgreSQL stores the product catalog.
- Do not add MAUI, Kotlin application code, React, or other stacks without a real
  requirement and implementation. Flutter’s Android host is Java.
