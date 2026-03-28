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

Important:

- `Suffix.linuxdoSpace` is semantic, not literal
- `Suffix.linuxdoSpace` now resolves to the current token owner's canonical
  mail namespace: `<owner_username>-mail.linuxdo.space`
- `Suffix.withSuffix("foo")` resolves to
  `<owner_username>-mailfoo.linuxdo.space`
- active semantic `-mail<suffix>` registrations are synchronized to
  `PUT /v1/token/email/filters`
- the legacy default alias `<owner_username>.linuxdo.space` still matches the
  default semantic binding automatically
- consumer code should keep using `Suffix.linuxdoSpace` instead of hardcoding
  a concrete `*-mail.linuxdo.space` namespace

## Local Verification Status

Current environment does not have Dart SDK installed, so this SDK was not compiled or run locally in this session.

## Build (when Dart is available)

```bash
dart pub get
dart analyze
```
