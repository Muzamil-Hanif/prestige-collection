# PostToolUse Hook

After using a tool:

## Verification Checklist

- [ ] **Change applied correctly** — Did the tool do what I expected?
- [ ] **Syntax errors** — Run linter/formatter if applicable
- [ ] **Broken imports** — Check that dependencies resolve
- [ ] **Tests passing** — Did I break any existing tests?
- [ ] **Summarize change** — What actually changed?

## By Tool Type

### Edit/Write (Code Changes)
- [ ] Dart syntax valid? (no compile errors)
- [ ] Imports available and correct?
- [ ] Follows design tokens if UI?
- [ ] No magic numbers or hardcoded values?

### Bash (Terminal Commands)
- [ ] Command succeeded (exit code 0)?
- [ ] Output as expected?
- [ ] No unintended side effects?
- [ ] Did it modify any critical files?

### API/HTTP Calls
- [ ] Response status code correct?
- [ ] Data structure matches expected schema?
- [ ] Error handling in place?

## Quick Fixes
- Run `dart format` if Dart file changed
- Run `flutter analyze` for analysis
- Check `git diff` to review exact changes
- Run relevant test suite before committing

## Common Issues
- ❌ Import paths wrong → check relative paths from project root
- ❌ Syntax errors → run formatter
- ❌ Breaking changes → check git diff
- ❌ Design tokens not used → verify against `design.md`

## Document Changes
If substantive change:
- Update `CLAUDE.md` if architecture/commands changed
- Update in-code comments if logic is non-obvious
- Update tests if behavior changed
