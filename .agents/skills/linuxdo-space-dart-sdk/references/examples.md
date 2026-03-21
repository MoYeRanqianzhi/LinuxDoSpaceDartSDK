# Task Templates

## Create one exact binding

```dart
final mailbox = client.bind(prefix: 'alice', suffix: Suffix.linuxdoSpace);
```

## Create one catch-all

```dart
final catchAll = client.bind(
  pattern: r'.*',
  suffix: Suffix.linuxdoSpace,
  allowOverlap: true,
);
```

## Route one message locally

```dart
final targets = client.route(message);
```

