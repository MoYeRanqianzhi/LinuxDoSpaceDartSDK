---
name: linuxdo-space-dart-sdk
description: Use when writing or fixing Dart code that consumes or maintains the LinuxDoSpace Dart SDK under sdk/dart. Use for git-based package integration, client construction, stream consumption, mailbox bindings, allowOverlap semantics, lifecycle/error handling, release guidance, and local validation.
---

# LinuxDoSpace Dart SDK

Read [references/consumer.md](references/consumer.md) first for normal SDK usage.
Read [references/api.md](references/api.md) for exact public Dart API names.
Read [references/examples.md](references/examples.md) for task-shaped snippets.
Read [references/development.md](references/development.md) only when editing `sdk/dart`.

## Workflow

1. Treat the package name as `linux_do_space`, imported from `package:linux_do_space/linux_do_space.dart`.
2. The SDK root relative to this `SKILL.md` is `../../../`.
3. Preserve these invariants:
   - one `Client` owns one upstream HTTPS stream
   - `Client.listen()` is the full-stream `Stream<MailMessage>`
   - `Client.bind(...)` creates mailbox bindings locally
   - `MailBox.listen()` exposes a mailbox-local `Stream<MailMessage>`
   - mailbox queues activate only while mailbox listen is active
   - `Suffix.linuxdoSpace` is semantic and resolves after `ready.owner_username`
   - exact and regex bindings share one ordered chain per suffix
   - `allowOverlap=false` stops at first match; `true` continues
   - remote `baseUrl` must use `https://`
4. Keep README, source, and workflows aligned when behavior changes.
5. Validate with the commands in `references/development.md`.

## Do Not Regress

- Do not document pub.dev publication; current release path is tag-pinned git or GitHub Release source archive.
- Do not describe `listen()` as taking a timeout parameter; Dart uses stream APIs plus constructor timeouts.
- Do not add hidden pre-listen mailbox buffering.
