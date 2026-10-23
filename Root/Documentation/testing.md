# Testing

## Flutter tests

```bash
./Root/Scripts/test-flutter.sh
```

| Test file | Covers |
|---|---|
| `test/qr_payload_parser_test.dart` | JSON, URL, plain identifiers/barcodes; malformed, empty, oversized, control characters |
| `test/local_product_repository_test.dart` | Lookup by ID, barcode, QR payload; out of stock; missing; corrupt data |
| `test/remote_product_repository_test.dart` | In stock, zero quantity, 404, 401, 500, malformed JSON |
| `test/scanner_view_model_test.dart` | Success, out of stock, not found, error, lock, duplicate, reset, retry |
| `test/result_panel_test.dart` | All result states and full product details |
| `test/auth_test.dart` | Local credentials and `LoginViewModel` states |
| `test/login_screen_test.dart` | Login rendering, success, error, validation, demo hint, English/Azerbaijani/Russian |

Current result: **68/68 passing**. `flutter analyze` reports no issues.

## C# core tests

```bash
./Root/Scripts/test-csharp.sh
```

| Area | Coverage |
|---|---|
| Parser | JSON, URL, plain identifiers/barcodes; malformed, empty, oversized, control characters |
| Local repository | ID, barcode, QR payload, out of stock, missing, corrupt data |
| Remote repository | In stock, zero quantity, 404, 401, 500, malformed JSON |
| ViewModel | Success, out of stock, not found, error, lock, duplicate, reset, retry |

Current result: **45/45 passing**.

## Backend checks

Start PostgreSQL and the API (see `postgresql-backend.md`), then:

```bash
curl http://127.0.0.1:8080/health
```

```bash
curl http://127.0.0.1:8080/products/PHN-001
```

```bash
curl http://127.0.0.1:8080/products/2000000000015
```

```bash
curl http://127.0.0.1:8080/products/PHN-003
```

```bash
curl -i http://127.0.0.1:8080/products/UNKNOWN
```

Add a product and confirm it is recognized immediately:

```bash
curl -X POST http://127.0.0.1:8080/products -H 'Content-Type: application/json' -d '{"id":"TEST-011","name":"Depot Test","description":"Test","color":"Black","quantity":2,"barcode":"2999999999999","qrCode":"{\"id\":\"TEST-011\"}"}'
```

```bash
curl http://127.0.0.1:8080/products/2999999999999
```

Expected:

- Health: `{"status":"ok"}`
- PHN-001 and its barcode: Aurora X1, quantity 12, `inStock: true`
- PHN-003: Pulse 7, quantity 0, `inStock: false`
- UNKNOWN: HTTP 404

## Manual device checklist

Generate codes from `product-codes.md`.

| # | Scenario | Steps | Expected |
|---|---|---|---|
| 1 | Valid login | Enter `test` / `test` | Home opens; camera not started |
| 2 | Wrong password | `test` / `wrong` | Error; Home stays closed |
| 3 | Blank login | Tap sign in empty | Validation messages |
| 4 | Start scan | Tap “Scan code” on Home | Camera and overlay start |
| 5 | Back | Tap back in scanner | Returns to Home; camera stops |
| 6 | Sign out | Tap logout on Home | Returns to login |
| 7 | QR in stock | QR mode, scan `PHN-001` QR payload | Aurora X1, image + all fields, 12 in stock |
| 8 | Barcode in stock | Barcode mode, scan `2000000000015` | Aurora X1, image + all fields |
| 9 | Out of stock | Scan `PHN-003` or its barcode | Not in stock, product details visible |
| 10 | No such product | Scan `UNKNOWN-404` | No such product |
| 11 | Invalid code | Scan `not a valid code` | Unsupported code |
| 12 | Mode switch | Switch QR ↔ Barcode | Square vs wide frame; state resets |
| 13 | Sound | Scan a code; toggle sound off and scan again | One cashier-style scanner beep; muted when off |
| 13b | Camera stop | After any result | Camera stops; “Scan another code” returns Home |
| 14 | Languages | Switch EN → AZ → RU | Login/Home/scanner/result text changes |
| 15a | Add from camera | Scan an unknown barcode, tap **Add to depot**, fill the name, save | Product saved and shown; scanning it again finds it |
| 15b | Duplicate add | Add the same code twice | “This code is already in the depot.” |
| 15c | Identify phone | Phone mode, frame a phone back, tap Identify | Model and confidence shown; in-stock, Not in stock or not-in-depot result |
| 15d | No key | Run the API without `GEMINI_API_KEY`, tap Identify | “Phone recognition is not set up on the server.” |
| 15 | New product | `POST /products`, then scan its barcode | New product appears without reinstall |
| 16 | Permission denied | Deny camera | Permission panel with settings path |
| 17 | Camera busy | Open camera in another app | Camera error + retry |
| 18 | Backend unreachable | Remote mode, stop API | Could not reach the server; retry |
| 18b | Cable-free scan | Disconnect USB; scan over Wi-Fi/mobile data | Product loads from the public API |
| 19 | API 500 | Force API failure | Server unavailable |
| 20 | Repeated scans | Hold one code steady | At most one lookup until reset |
| 21 | Background/resume | Home, then reopen | Camera restarts; no stale lookup |
| 22 | Rotation | Rotate on each state | State survives; preview recovers |
| 23 | Real-device install | `install-flutter.sh` | Installs, launches, scans |

## Device notes

- Minimum Android 8 (API 24); test a modern release too.
- Test light and dark themes.
- Test printed and on-screen codes.
- Online test: run `./Root/Scripts/start-backend.sh`, build with
  `--dart-define=API_BASE_URL=https://<tunnel>.trycloudflare.com/`, and scan with
  mobile data (Wi-Fi off) to prove cable-free operation.
- USB fallback: `adb reverse tcp:8080 tcp:8080`.
- Logs:

```bash
./Root/Scripts/device-logs.sh
```
