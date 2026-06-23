---
description: Launch the iOS Simulator and run the PrestigeCollection Flutter app on iPhone 15 Pro
allowed-tools: Bash(open *) Bash(xcrun *) Bash(flutter run *) Bash(sleep *)
disable-model-invocation: true
---

Run the PrestigeCollection app on the iPhone 15 Pro simulator:

1. Run `open -a Simulator`
2. Run `xcrun simctl boot "iPhone 15 Pro" || true`
3. Run `sleep 5`
4. Run `flutter run -d 1C84ECA0-1C41-4A4B-8A5A-A49D9B4AF8FA`
