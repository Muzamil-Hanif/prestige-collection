---
description: Build the Flutter app for a target platform (ios/android/web/macos)
argument-hint: <platform>
allowed-tools: Bash(flutter *)
---

Build the Flutter app for $ARGUMENTS:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter build $ARGUMENTS --release`
4. Report the output artifact location.
