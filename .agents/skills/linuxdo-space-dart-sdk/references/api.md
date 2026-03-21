# API Reference

## Paths

- SDK root: `../../../`
- Package metadata: `../../../pubspec.yaml`
- Core implementation: `../../../lib/linux_do_space.dart`
- Consumer README: `../../../README.md`

## Public surface

- Types: `Suffix`, `LinuxDoSpaceException`, `AuthenticationException`, `StreamException`, `MailMessage`, `MailBox`, `Client`
- Client:
  - `Client(...)`
  - `listen()`
  - `bind(...)`
  - `route(message)`
  - `close()`
- MailBox:
  - `listen()`
  - `close()`
  - properties such as `mode`, `suffix`, `allowOverlap`, `prefix`, `pattern`, `address`, `closed`

## Semantics

- `listen()` returns Dart streams; there is no explicit listen-time timeout parameter.
- `bind(...)` requires exactly one of `prefix` or `pattern`.
- Regex bindings use full-match semantics.
- `Suffix.linuxdoSpace` is semantic, not literal.
