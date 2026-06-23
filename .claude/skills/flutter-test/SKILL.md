---
name: flutter-test
description: Run Flutter unit and widget tests with optional coverage
argument-hint: [--coverage]
disable-model-invocation: true
allowed-tools: Bash(flutter test *) Bash(dart *)
---

Run Flutter tests for the PrestigeCollection project:

1. Run `flutter test $ARGUMENTS`
2. If `--coverage` was passed, also run `flutter test --coverage` and summarise the lcov output.
3. On failure, show the failing test name and the assertion error clearly.
