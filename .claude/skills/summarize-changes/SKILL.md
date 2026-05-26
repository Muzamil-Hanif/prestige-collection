---
name: summarize-changes
description: Summarise current git diff and flag risks before committing
user-invocable: false
---

## Uncommitted Changes

!`git diff --stat HEAD 2>/dev/null || echo "No git changes"`

Summarise the changes in 2-3 bullets. Flag any:

- Missing error handling in new API calls
- Hardcoded URLs or credentials
- Dart files edited without running `dart format`
- Cart or auth state mutations that bypass `MainScreen` callbacks
