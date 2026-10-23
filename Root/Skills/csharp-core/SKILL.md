---
name: csharp-core
description: Work on the pure C# product core in Projects/MobileApp.CSharp — parser, Product model, repositories, ViewModel, and the 45-test console runner. No MAUI or Android UI.
---

# C# Core

The C# project is a `net10.0` library and console test runner. The Flutter app is
the mobile application; the C# ProductApi is the PostgreSQL backend. This core has
no MAUI, Android, camera, UI, or APK.

## Locations

- Solution: `Projects/MobileApp.CSharp/QRScanner.Core.slnx`
- Parser: `QRScanner.Core/Qr/QrPayloadParser.cs`
- Product: `QRScanner.Core/Models/Product.cs`
- Lookup results: `QRScanner.Core/Models/LookupResult.cs`
- Repositories: `QRScanner.Core/Data/`
- State: `QRScanner.Core/State/ScannerViewModel.cs`
- Tests: `QRScanner.Core.Tests/Program.cs`
- Documentation: `Root/Documentation/csharp-core.md`

## Commands

```bash
./Root/Scripts/test-csharp.sh
./Root/Scripts/build-csharp.sh
```

Direct commands:

```bash
cd Projects/MobileApp.CSharp
dotnet run --project QRScanner.Core.Tests/QRScanner.Core.Tests.csproj
dotnet build QRScanner.Core/QRScanner.Core.csproj
```

## Rules

- Keep `QRScanner.Core` free of MAUI, Android, UI, camera, and database references.
- Add a test whenever parsing, product lookup, or state changes.
- Keep out-of-stock distinct from not-found and failure.
- Do not invent an API endpoint or product rule.
- Never commit secrets or signing material.
- Do not add a MAUI project; Flutter is the mobile app.
