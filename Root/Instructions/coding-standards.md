# Coding Standards

## Dart / Flutter

- Follow `flutter_lints` and `dart format`.
- Prefer immutable classes and `const` constructors.
- Use sealed classes for finite state.
- Keep the parser free of Flutter and I/O imports.
- Use `ChangeNotifier` for scanner/login state.
- Handle camera permission, lifecycle, and mode changes explicitly.
- Do not hardcode user-facing text; add ARB entries for English, Azerbaijani,
  and Russian.
- Keep sound effects optional and non-blocking; scanning must work if audio fails.
- Add a `flutter_test` case whenever parsing, product lookup, auth, localization,
  or state changes.

## C#

- Modern C# (`LangVersion=latest`), nullable reference types enabled.
- Prefer records for immutable data and sealed types for closed hierarchies.
- Use `async`/`await`; do not block with `.Result` or `.Wait()`.
- Use `ConfigureAwait(false)` in `QRScanner.Core`.
- Keep `QRScanner.Core` free of MAUI, Android, UI, and camera references.
- Add a test whenever the parser, product lookup, or state machine changes.

## Backend / SQL

- Always use parameterized SQL; never concatenate user input.
- Keep the schema and seed in `Root/Infrastructure/postgres/init/`.
- Do not commit production credentials. Local development values must be
  documented as such.
- Return `404` for an unknown product; return `200` with `quantity: 0` for an
  out-of-stock product so the app can show its details.
- Do not expose the API publicly without authentication.

## Shared

- Keep functions small and single-purpose.
- No comments that restate the code. Comment only non-obvious constraints.
- No secrets, tokens, keystores, or signing material in the repository.
- Do not automatically open decoded URLs.
- Validate content length and reject control characters.
- Use HTTPS for release builds; cleartext HTTP is for local development only.
- Do not log decoded payloads, product data, passwords, or tokens.
