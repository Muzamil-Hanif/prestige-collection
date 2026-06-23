---
name: flutter-build
description: Build a release Flutter app for a specific platform
argument-hint: <ios|android|web|macos>
disable-model-invocation: true
allowed-tools: Bash(flutter *) Bash(dart *)
---

Build PrestigeCollection for the target platform: $ARGUMENTS

Steps:
1. `flutter clean`
2. `flutter pub get`
3. `flutter build $ARGUMENTS --release`
4. Report artifact path and file size.
