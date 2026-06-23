# PostCompact Hook

After context compaction / summarization:

## Memory Preservation Checklist

- [ ] **Important decisions preserved** — Are key architectural choices still documented?
- [ ] **Task progress tracked** — Is the current work state clear?
- [ ] **User requirements captured** — Will next context understand what we're building?
- [ ] **Critical context saved** — Design decisions, patterns, constraints?
- [ ] **File locations remembered** — Key file paths for ongoing work?

## What Must Not Be Lost

### Architecture Decisions
- State management approach (SharedPreferences + callbacks pattern)
- Why JWT is handled in `api_service.dart`
- Why categories are integers (0=All, 1–4=specific)
- Design system enforcement via `design.md`

### Ongoing Work
- Branch name and what it's implementing
- Open PRs and why they exist
- Known TODOs or blockers
- Test coverage expectations

### Patterns Used
- How cart syncing works (client ↔ server)
- Image URL normalization in API responses
- Order line item validation
- Search debouncing pattern

## Memory Files to Check
- `.claude/projects/-Users-devexcel-management-PrestigeCollection/memory/` — verify user, feedback, project, reference memories exist
- CLAUDE.md — project instructions preserved
- Recent git log — context of current branch

## Before Next Session
- Is the current branch goal clear?
- Are blocking issues documented?
- Are file paths/commands accurate?
- Would a new person understand the context?

## Red Flags
- ❌ Lost user preferences or feedback rules
- ❌ Outdated file paths or commands
- ❌ Forgotten task progress
- ❌ Architecture decisions not recorded
