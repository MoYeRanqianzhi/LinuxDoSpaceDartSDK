# Development Guide

## Workdir

```bash
cd sdk/dart
```

## Validate

```bash
dart pub get
dart analyze
```

## Release model

- Workflow file: `../../../.github/workflows/release.yml`
- Trigger: push tag `v*`
- Current release output is a source archive uploaded to GitHub Release
- The package is not currently published to pub.dev

## Keep aligned

- `../../../pubspec.yaml`
- `../../../lib/linux_do_space.dart`
- `../../../README.md`
- `../../../.github/workflows/ci.yml`
- `../../../.github/workflows/release.yml`
