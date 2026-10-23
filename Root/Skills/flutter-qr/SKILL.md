---
name: flutter-qr
description: Work on the Flutter Scanner app in Projects/MobileApp — QR and barcode modes, product lookup, stock states, login, tests, and Android APK builds.
---

# Flutter Scanner

The Flutter app in `Projects/MobileApp` is the Android application (display name
**Scanner**). It scans QR codes and 1D barcodes and looks up phone products.

## Locations

- Entry: `Projects/MobileApp/lib/main.dart`
- Auth: `lib/src/auth/`, `state/login_view_model.dart`, `ui/login_screen.dart`
- Home/Scan gate: `lib/src/ui/home_screen.dart`
- Product model: `lib/src/models/product.dart`
- Parser: `lib/src/qr/qr_payload_parser.dart`
- Data: `lib/src/data/` (`local_product_repository`, `remote_product_repository`)
- State: `lib/src/state/`
- Scanner and modes: `lib/src/ui/scanner_screen.dart`
- Results: `lib/src/ui/result_panel.dart`
- Localization: `lib/l10n/`, `ui/language_button.dart`
- Sounds: `lib/src/services/sound_service.dart`, `assets/sounds/`
- Images: `assets/images/phones/`, `ui/product_image.dart`
- Local catalog: `assets/products.json`
- Tests: `test/`

## Commands

```bash
./Root/Scripts/bootstrap-flutter.sh
./Root/Scripts/test-flutter.sh
./Root/Scripts/build-flutter.sh
./Root/Scripts/install-flutter.sh
./Root/Scripts/device-logs.sh
```

## Behavior

- Login is required (`test` / `test`); Home then requires tapping **Scan code**
  before the camera starts.
- QR mode scans `qrCode`; Barcode mode scans EAN/UPC/Code 128/39/93/ITF/Codabar.
- Lookup matches product ID, barcode, or QR payload; no remote product cache.
- Quantity > 0 → success; quantity 0 → Not in stock; no match → No such product.
- Remote mode uses the ProductApi/PostgreSQL; new `POST /products` rows are
  recognized on the next scan without rebuilding the app.
- Languages: English, Azerbaijani, Russian. One cashier-style scanner beep per scan; camera
  stops after a result and “Scan another code” returns Home.
- Product illustrations are local SVGs showing the colored phone back and camera
  module; unknown/new products use `default.svg`.
- App detail: `Root/Documentation/product-codes.md`.

## Rules

- Keep `lib/src/qr/` free of Flutter and I/O imports.
- Add a `flutter_test` case for parsing, product lookup, auth, localization, or
  state changes.
- Do not hardcode UI text; update all three ARB files.
- Do not invent an API endpoint or product rule.
- Never commit secrets or signing material.
- Do not add MAUI, Kotlin application code, React, or direct PostgreSQL access.
