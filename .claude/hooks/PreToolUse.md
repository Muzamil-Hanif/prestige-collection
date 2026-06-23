# PreToolUse Hook

Before using any tool (edit, terminal, search, etc.):

## Safety Checklist

- [ ] **Think before acting** — What am I about to do and why?
- [ ] **Check conventions** — Does this follow project patterns in CLAUDE.md?
- [ ] **Verify file** — Am I editing the correct file and location?
- [ ] **Consider side effects** — What else might this change break?
- [ ] **Permissions** — Am I allowed to run this command/tool?

## Tool-Specific Checks

### Edit/Write Tools
- Does the change align with `design.md` (if UI)?
- Are imports correct and paths relative to project root?
- Am I using existing utilities (avoid duplicating code)?

### Bash Commands
- Is this a read-only operation or does it modify state?
- Will this affect shared code or CI/CD?
- Are there safer alternatives?

### API Calls
- Does the endpoint exist in backend?
- Is auth/JWT handling correct?
- Have I tested the endpoint first?

## Questions to Ask Yourself
1. "Is there already a utility/function for this?"
2. "Will this break any existing feature?"
3. "Does this follow the project's code style?"
4. "Should I verify this works before committing?"

## Red Flags 🚩
- Hardcoded values (use design tokens instead)
- Magic numbers or colors not in `design.md`
- Duplicated code (refactor to reuse)
- Breaking existing test suites
- Running shell commands with unsanitized user input
