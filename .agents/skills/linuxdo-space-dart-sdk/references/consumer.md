# Consumer Guide

## Install

Use a tag-pinned git dependency:

```yaml
dependencies:
  linux_do_space:
    git:
      url: https://github.com/MoYeRanqianzhi/LinuxDoSpaceDartSDK.git
      ref: v0.1.1
```

Import shape:

```dart
import 'package:linux_do_space/linux_do_space.dart';
```

## Full stream

```dart
final client = Client('lds_pat...');
try {
  await for (final item in client.listen()) {
    print('${item.address} ${item.subject}');
  }
} finally {
  await client.close();
}
```

## Mailbox binding

```dart
final mailbox = client.bind(prefix: 'alice', suffix: Suffix.linuxdoSpace);
try {
  await for (final item in mailbox.listen()) {
    print(item.subject);
  }
} finally {
  await mailbox.close();
}
```

## Key semantics

- Constructor timeouts live on `Client(...)`, not on `listen()`.
- `route(message)` matches only `message.address`.
- Full-stream messages use a primary projection address.
- Mailbox messages use matched-recipient projection addresses.
