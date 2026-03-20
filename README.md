# LinuxDoSpace Dart SDK

This directory contains a Dart SDK implementation for LinuxDoSpace mail stream protocol.

## Scope

- `Client`, `Suffix`, `MailMessage`
- Errors: auth and stream errors (auth fatal is persisted)
- Full token listener stream
- Local binding (exact/regex), ordered matching, allow overlap
- `route`, `close`
- Multi-recipient dispatch keeps mailbox `message.address` as current recipient
- MIME header/body parsing fills common fields (`subject`, address headers, text/html)

## Local Verification Status

Current environment does not have Dart SDK installed, so this SDK was not compiled or run locally in this session.

## Build (when Dart is available)

```bash
dart pub get
dart analyze
```
