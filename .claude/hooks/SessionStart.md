# SessionStart Hook

You are now starting a new coding session.

## Project Context
- Understand the project structure and tech stack.
- Be aware of coding standards and architecture.
- Maintain consistency with previous decisions.

## Quick Reference

### Stack
- **Frontend:** Flutter (Dart) — `/PrestigeCollection/`
- **Backend:** NestJS (TypeScript) — `/prestige-collection-backend/`
- **State:** SharedPreferences + in-memory (MainScreen callbacks)
- **API:** REST with JWT auth

### Key Files
- `lib/main.dart` — app entry, theme, routing
- `lib/services/api_service.dart` — all API calls
- `design.md` — UI design tokens (follow strictly)
- `CLAUDE.md` — project-specific instructions

### Commands
```bash
flutter pub get && flutter run -d chrome              # Web dev
flutter run --dart-define=API_BASE_URL=http://IP:3000  # Device
cd ../prestige-collection-backend && npm run start:dev      # Backend
```

## Checklist
- [ ] Read CLAUDE.md if first time on this branch
- [ ] Check current git branch and recent commits
- [ ] Review design.md before building UI
- [ ] Verify backend is running (if needed)
