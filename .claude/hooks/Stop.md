# Stop Hook

Before ending the session:

## Session Closure Checklist

- [ ] **Summarize accomplishments** — What got done this session?
- [ ] **List remaining TODOs** — What's left to do?
- [ ] **Document open issues** — Any blockers or problems?
- [ ] **Suggest next steps** — What should the next session focus on?
- [ ] **Commit changes** — Has all work been committed?

## What to Document

### What Was Accomplished
- Feature built or bug fixed
- Tests added or updated
- Documentation updated (CLAUDE.md, design.md)
- Dependencies added/removed
- Architecture decisions made

### What's Left
- Incomplete features or branches
- Failing tests that need attention
- TODOs left in code
- Design reviews pending
- Backend API calls not yet implemented

### Known Issues
- Any regressions discovered
- Edge cases not handled
- Performance concerns
- Design deviations needed

### Next Steps
- High-priority tasks for next session
- Branch merge strategy (PR or direct?)
- Testing needed before merge
- Stakeholder approval required?
- Backend dependencies needed?

## State to Preserve in Memory
If work is incomplete:
- Current branch purpose and progress
- Blockers or decisions needed from user
- File locations for ongoing work
- Commands to resume work

## Final Checks
- [ ] No uncommitted changes (except `.claude/` files)
- [ ] Tests passing (if applicable)
- [ ] Code follows design.md and CLAUDE.md
- [ ] Memory files updated with progress
- [ ] Clear message for next session

## Example Summary
```
Session: Feature implementation
✅ Completed: Checkout page UI, address validation
⏳ In Progress: Payment integration (backend API not ready)
❌ Blocked: Awaiting backend /orders endpoint
Next: Integrate payment once API is ready
```
