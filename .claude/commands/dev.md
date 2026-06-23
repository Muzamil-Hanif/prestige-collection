---
description: Start the full dev environment — NestJS backend in background then Flutter on iPhone 15 Pro simulator
allowed-tools: Bash(cd *) Bash(npm run *) Bash(open *) Bash(xcrun *) Bash(flutter run *) Bash(sleep *)
disable-model-invocation: true
---

Start the full PrestigeCollection dev environment:

1. Run `cd /Users/devexcel-management/prestige-collection-backend && npm run start:dev &` to start the backend in the background
2. Run `sleep 3` to give the backend time to initialize
3. Run `open -a Simulator`
4. Run `xcrun simctl boot "iPhone 15 Pro" || true`
5. Run `sleep 5`
6. Run `cd /Users/devexcel-management/PrestigeCollection && flutter run -d 1C84ECA0-1C41-4A4B-8A5A-A49D9B4AF8FA`
