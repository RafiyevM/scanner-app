# Product Codes

Ten demo phone products are shared by the Flutter app, the C# core tests, and the
PostgreSQL seed.

## Products

| ID | Product | Color | Stock | Barcode (EAN-13) | QR payload |
|---|---|---|---|---|---|
| `PHN-001` | Aurora X1 | Midnight Black | 12 | `2000000000015` | `{"id":"PHN-001","type":"phone"}` |
| `PHN-002` | Nova S2 | Ocean Blue | 7 | `2000000000022` | `{"id":"PHN-002","type":"phone"}` |
| `PHN-003` | Pulse 7 | Arctic White | **0** | `2000000000039` | `{"id":"PHN-003","type":"phone"}` |
| `PHN-004` | Vertex Pro | Graphite Gray | 4 | `2000000000046` | `{"id":"PHN-004","type":"phone"}` |
| `PHN-005` | Lumen Mini | Coral Pink | 15 | `2000000000053` | `{"id":"PHN-005","type":"phone"}` |
| `PHN-006` | Orion Max | Forest Green | **0** | `2000000000060` | `{"id":"PHN-006","type":"phone"}` |
| `PHN-007` | Aero Lite | Sky Blue | 9 | `2000000000077` | `{"id":"PHN-007","type":"phone"}` |
| `PHN-008` | Titan Edge | Titanium Silver | 3 | `2000000000084` | `{"id":"PHN-008","type":"phone"}` |
| `PHN-009` | Zenith 5G | Deep Purple | **0** | `2000000000091` | `{"id":"PHN-009","type":"phone"}` |
| `PHN-010` | Solstice | Sunset Gold | 6 | `2000000000107` | `{"id":"PHN-010","type":"phone"}` |

Products with quantity `0` must show **Not in stock**, while still displaying the
product details.

## Scan modes

The app has a **QR / Barcode** selector.

- **QR** scans `BarcodeFormat.qrCode`.
- **Barcode** scans EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93,
  ITF, and Codabar.

A lookup matches the product by:

1. product ID (case-insensitive)
2. barcode (exact)
3. QR payload (case-insensitive)

## Expected results

| Code | Result |
|---|---|
| `PHN-001` or `2000000000015` or its QR payload | Product found, 12 in stock |
| `PHN-003` or `2000000000039` or its QR payload | Not in stock |
| `PHN-006` or `PHN-009` | Not in stock |
| `UNKNOWN-404` | No such product |
| `not a valid code` | Unsupported code |

## Generate test codes

Any QR/barcode generator can produce these values. Use EAN-13 for the barcode
mode and the JSON payload (or the product ID) for the QR mode.
