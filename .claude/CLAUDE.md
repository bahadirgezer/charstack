# Charstack — Claude Context (Repo-Level)

## Project Overview
Charstack is a minimal iOS daily task manager built around **four day regions** (Morning, Afternoon, Evening, Backlog) using a **1-3-5 rule** per active region. The app is SwiftUI-only, targeting iOS 26+ with SwiftData persistence.

## Tech Stack
- **Language**: Swift 6.0 (strict concurrency)
- **UI**: SwiftUI (100%, no UIKit)
- **Persistence**: SwiftData (CloudKit sync in Phase 2)
- **Auth (Phase 3+)**: Sign in with Apple + Google Sign-In via BaaS (TBD: Firebase or Supabase)
- **Minimum iOS**: 26.0
- **Architecture**: MVVM with lightweight coordinator navigation

## Commands
- **Build**: `xcodebuild build -scheme Charstack -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Test**: `xcodebuild test -scheme Charstack -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **Lint**: `swiftlint` 

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
├── CharstackApp.swift       # @main entry point, ModelContainer setup
├── ContentView.swift        # Legacy placeholder (superseded by RootView)
├── App/
│   ├── AppCoordinator.swift # NavigationStack coordinator with Route enum
│   └── RootView.swift       # Root view: NavigationStack + destination mapping
├── Core/
│   ├── Models/              # CharstackTask (@Model), Region, TaskBucket, TaskStatus enums
│   ├── Services/            # TaskService (CRUD + 1-3-5 + rollover)
│   └── Persistence/         # ModelContainerSetup (production + testing containers)
├── Features/
│   ├── Today/               # TodayView, TodayViewModel, Components/RegionCard
│   ├── RegionFocus/         # RegionFocusView, RegionFocusViewModel, Components/TaskRow, QuickAddBar
│   ├── Backlog/             # (Week 3) BacklogView + ViewModel
│   └── Settings/            # (Phase 3) SettingsView
├── Shared/
│   ├── Extensions/          # Date+Extensions
│   ├── Theme/               # Theme (Colors, Typography, Spacing, CornerRadius)
│   ├── Preview/             # PreviewData (sample tasks for SwiftUI previews)
│   └── Components/          # (Week 3+) Shared UI components
├── Assets.xcassets
CharstackTests/
├── Models/                  # Region, TaskBucket, TaskStatus, CharstackTask tests
├── Services/                # TaskServiceTests (CRUD, constraints, rollover)
├── Extensions/              # DateExtensionsTests
```

## Session & Tracking Files
- `.claude/TODAY.md` — Current session tasks and progress. Check at start of every session. Update as you work.
- `.claude/TODO.md` — Longer-term work items. Extension of TODAY.md for items that span sessions.
- `context.md` files — Brain dumps in directories with significant work. Written for the *next* session.

## Documentation (keep these updated — MANDATORY)
These docs are the source of truth. **Whenever you make changes that affect any of these, update them in the same session.** Don't defer doc updates — stale docs are worse than no docs.
- `docs/PROJECT_BRIEF.md` — Original concept and vision
- `docs/REQUIREMENTS.md` — Functional/non-functional requirements + App Store compliance
- `docs/ARCHITECTURE.md` — Technical decisions, data models, patterns, project structure
- `docs/ROADMAP.md` — Development phases and milestones (mark items ✅ when done)
- `CHANGELOG.md` — Version history (add entries under `[Unreleased]`)

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
Phase 1 (MVP) Week 1 (Data Layer) and Week 2 (UI Layer) are complete. Week 3 (Backlog & Day Rollover) is next.
See `.claude/TODAY.md` for current tasks.
