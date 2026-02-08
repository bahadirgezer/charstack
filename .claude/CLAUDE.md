# Charstack — Claude Context (Repo-Level)

## Project Overview
Charstack is a minimal iOS daily task manager built around **four day regions** (Morning, Afternoon, Evening, Backlog) using a **1-3-5 rule** per active region. The app is SwiftUI-only, targeting iOS 17+ with SwiftData persistence.

## Tech Stack
- **Language**: Swift 6.0 (strict concurrency)
- **UI**: SwiftUI (100%, no UIKit)
- **Persistence**: SwiftData (CloudKit sync in Phase 2)
- **Auth (Phase 3+)**: Sign in with Apple + Google Sign-In via BaaS (TBD: Firebase or Supabase)
- **Minimum iOS**: 17.0
- **Architecture**: MVVM with lightweight coordinator navigation

## Commands
- **Build**: `xcodebuild build -scheme Charstack -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Test**: `xcodebuild test -scheme Charstack -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Lint**: `swiftlint` (once configured)

## Code Style
- SwiftLint enforced (see `.swiftlint.yml` when added)
- Prefer verbose, self-documenting variable and function names
- Prefer value types (structs/enums) over reference types where possible
- Use Swift Concurrency (async/await) over completion handlers
- Use `@MainActor` on all ViewModels
- No force unwraps — handle optionals explicitly
- Doc comments on all public APIs

## Architecture
- **MVVM**: View → ViewModel (@Observable) → Model (SwiftData) + Services
- **Feature modules**: Each feature (Today, RegionFocus, Backlog, Settings) is self-contained under `Features/`
- **Service layer**: Business logic lives in `Core/Services/`, never in Views or ViewModels directly
- **Shared components**: Reusable UI pieces live in `Shared/Components/`

## Key Domain Concepts
- **Region**: Morning, Afternoon, Evening, or Backlog — time-of-day buckets
- **TaskBucket**: Must (1 per region), Complementary (max 3), Misc (max 5)
- **1-3-5 Rule**: Each active region enforces this constraint
- **Day Rollover**: At day boundary, incomplete tasks auto-move to Backlog
- **Backlog**: Unconstrained holding area for deferred/rolled-over tasks

## CloudKit Constraints (important for model design)
- No `@Attribute(.unique)` on any synced property
- All model properties MUST have default values or be optional
- All relationships MUST be optional
- Violating these causes silent sync failure

## Project Structure
```
Charstack/
├── App/                     # Entry point, app coordinator
├── Core/
│   ├── Models/              # SwiftData @Model classes + enums
│   ├── Services/            # TaskService, DayRolloverService, etc.
│   └── Persistence/         # ModelContainer setup
├── Features/
│   ├── Today/               # Dashboard with 4 region cards
│   ├── RegionFocus/         # Single-region task list (1-3-5)
│   ├── Backlog/             # Backlog list + triage
│   └── Settings/            # User preferences
├── Shared/
│   ├── Components/          # Reusable views (TaskRow, EmptyState, etc.)
│   ├── Extensions/          # Date+, View+, etc.
│   └── Theme/               # Colors, Typography
├── Resources/               # Assets, Localizable.strings
└── Tests/
    ├── CharstackTests/      # Unit tests
    └── CharstackUITests/    # UI tests
```

## Session & Tracking Files
- `.claude/TODAY.md` — Current session tasks and progress. Check at start of every session. Update as you work.
- `.claude/TODO.md` — Longer-term work items. Extension of TODAY.md for items that span sessions.
- `context.md` files — Brain dumps in directories with significant work. Written for the *next* session.

## Documentation (keep these updated)
These docs are the source of truth. When making changes that affect any of them, update them:
- `docs/PROJECT_BRIEF.md` — Original concept and vision
- `docs/REQUIREMENTS.md` — Functional/non-functional requirements + App Store compliance
- `docs/ARCHITECTURE.md` — Technical decisions, data models, patterns
- `docs/ROADMAP.md` — Development phases and milestones
- `CHANGELOG.md` — Version history

## App Store Compliance (Phase 2+)
When accounts are added, these are **mandatory** (Apple rejects without them):
- Account deletion in-app (Guideline 5.1.1(v)) — Settings > Account > Delete
- Sign in with Apple if any third-party login offered (Guideline 4.8)
- Privacy policy in-app AND in App Store Connect (Guideline 5.1.1)
- Privacy nutrition labels accurate in App Store Connect
- Demo account for App Store reviewers
- Minimal data collection during registration
See `docs/REQUIREMENTS.md` section 2.6 for full details.

## Git Conventions
- **Commit style**: Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`)
- **Branch strategy**: `main` (stable releases) ← `develop` (active work) ← `feature/*` branches
- **Tags**: Semantic versioning (`v0.1.0`, `v1.0.0`, etc.)

## Current Phase
Phase 0 (Foundation) is complete. Phase 1 (MVP) is next.
See `.claude/TODAY.md` for current tasks.
