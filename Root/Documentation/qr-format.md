# QR and Barcode Content

The scanner reads **QR codes** and **1D barcodes**. The decoded content is
normalized to a lookup code, then matched against product ID, barcode, or QR
payload.

## Scan formats

- **QR mode:** `BarcodeFormat.qrCode`.
- **Barcode mode:** EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39, Code 93,
  ITF, Codabar.

## Accepted content

The parser accepts, in order:

1. **JSON** starting with `{` or `[`, containing one of
   `id`, `recordId`, `record_id`, `code`, `qr`
2. **HTTP/HTTPS URL** carrying one of those keys, or an identifier as the last
   path segment
3. **Plain identifier** matching `^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$`

Plain EAN-13 digits (for example `2000000000015`) match the plain identifier
rule.

### Limits

| Rule | Value |
|---|---|
| Maximum raw content | 1024 characters |
| Maximum identifier | 128 characters |
| Control characters | rejected |
| Spaces in a plain identifier | rejected |
| Automatic URL opening | never |

## Product matching

A product matches when its ID, barcode, or QR payload equals the normalized code.

- `quantity > 0` → product found / in stock
- `quantity == 0` → not in stock, details still shown
- No match → no such product

Ten demo phone products and their codes are listed in `product-codes.md`.

## Demo codes

| Code | Result |
|---|---|
| `PHN-001` / `2000000000015` / its QR payload | Aurora X1, 12 in stock |
| `PHN-003` / `2000000000039` | Pulse 7, not in stock |
| `PHN-006` / `PHN-009` | Not in stock |
| `UNKNOWN-404` | No such product |
| `not a valid code` | Unsupported code |

## Implementation locations

| Concern | Path |
|---|---|
| Flutter parser | `Projects/MobileApp/lib/src/qr/qr_payload_parser.dart` |
| Flutter tests | `Projects/MobileApp/test/qr_payload_parser_test.dart` |
| Flutter products | `Projects/MobileApp/assets/products.json` |
| C# parser | `Projects/MobileApp.CSharp/QRScanner.Core/Qr/QrPayloadParser.cs` |
| C# tests | `Projects/MobileApp.CSharp/QRScanner.Core.Tests/Program.cs` |

## Tightening the format later

When the real barcode/QR format is known:

1. Restrict the accepted formats in both parsers if needed.
2. Keep the success/invalid result contracts unchanged.
3. Add real valid and invalid samples to both test suites.
4. Update this document and `product-codes.md`.
