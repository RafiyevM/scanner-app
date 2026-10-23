# C# Core

`Projects/MobileApp.CSharp` is a pure C# implementation of the QR/barcode parser,
product lookup, and scan state machine.

It is a `net10.0` class library plus a console test runner. It has **no MAUI,
Android, camera, UI, or APK**. The mobile app is Flutter.

## Projects

```text
Projects/MobileApp.CSharp/
├── QRScanner.Core.slnx
├── QRScanner.Core/
│   ├── Qr/                 QrFormat, QrPayload, QrParseResult, QrPayloadParser
│   ├── Models/             Product, LookupResult
│   ├── Data/               IProductStore, IProductRepository,
│   │                       LocalProductRepository, RemoteProductRepository
│   └── State/              ScanUiState, ScannerViewModel
└── QRScanner.Core.Tests/
    └── Program.cs          Console test runner
```

## Product model

`Product` contains:

- `Id`
- `Name`
- `Description`
- `Color`
- `Quantity`
- `Barcode`
- `QrCode`
- `InStock` (computed from `Quantity > 0`)

Lookup matches product ID, barcode, or QR payload. A match with quantity `0`
returns `LookupResult.OutOfStock`, and the ViewModel emits
`ScanUiState.OutOfStock` rather than a failure.

## Tests

```bash
./Root/Scripts/test-csharp.sh
```

Current result: **45/45 passing**.

Coverage:

- JSON, URL, plain identifier, and barcode parsing
- Malformed, empty, oversized, control-character input
- Local lookup by ID, barcode, and QR payload
- Out-of-stock and missing products
- Remote in-stock, zero-quantity, 404, 401, 500, malformed JSON
- ViewModel success, out of stock, not found, error, lock, duplicate, reset,
  retry, and state order

## Build

```bash
./Root/Scripts/build-csharp.sh
```

This builds `QRScanner.Core` only. It does not produce an Android APK.

## Usage

Local data:

```csharp
var repository = new LocalProductRepository(myProductStore);
var viewModel = new ScannerViewModel(repository);
viewModel.StateChanged += (_, state) => { /* observe */ };
await viewModel.OnQrDetectedAsync(rawCode);
```

Remote data:

```csharp
var client = new HttpClient { BaseAddress = new Uri("http://127.0.0.1:8080/") };
var repository = new RemoteProductRepository(client);
```

`IProductStore` is implemented by the host; the core does not bundle an asset
loader because it has no platform dependencies.

## Remote contract

```http
GET {baseUrl}products/{code}
Accept: application/json
```

Response fields: `id`, `name`, `description`, `color`, `quantity`, `barcode`,
`qrCode`, `inStock`. `404` means no such product. Status/error mapping is
documented in `Root/Documentation/api-integration.md`.

## Configuration

The host supplies the local store or the configured `HttpClient`. There is no
Android configuration layer in this project.

## Security

- No secrets, tokens, or signing material.
- Cleartext HTTP is for local development only.
- Decoded payloads and product data are not logged.
