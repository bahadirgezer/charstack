# Features/ — Context for Next Session

## What's Here
Feature modules organized by screen. Each feature has its own View, ViewModel, and Components/ subdirectory.

### Today/ (Complete — Week 2)
- **TodayView.swift** — Main dashboard. ScrollView with 4 RegionCards, daily progress bar, rollover banner, empty state. Uses `TodayViewModel`.
- **TodayViewModel.swift** — `@Observable @MainActor`. Holds `tasksByRegion: [Region: [CharstackTask]]`. Loads today's tasks grouped by region, triggers day rollover, tracks completion stats. All data flows through `TaskService`.
- **Components/RegionCard.swift** — Summary card per region. Shows icon, must-do title (or placeholder), bucket fill counts, progress bar. Tapping calls `onTap` closure which navigates via coordinator.

### RegionFocus/ (Complete — Week 2)
- **RegionFocusView.swift** — Detailed view for a single region. For constrained regions, shows tasks grouped into Must-Do/Complementary/Misc sections. For backlog, shows ungrouped list with "Move to..." context menu. Has a `QuickAddBar` at the bottom. Edit sheet for title/notes.
- **RegionFocusViewModel.swift** — `@Observable @MainActor`. Holds tasks for a single region. CRUD via TaskService. Tracks edit sheet state.
- **Components/TaskRow.swift** — Single task row. Checkbox (with `contentTransition(.symbolEffect(.replace))`), title (strikethrough on done), notes preview, bucket badge. Swipe actions: complete (leading), delete (trailing). Context menu: edit, move, delete.
- **Components/QuickAddBar.swift** — Inline task creation bar. Text field + bucket picker (Menu) + add button. Defaults to Misc bucket. Clears after add for rapid entry.

### Backlog/ (Week 3 — Not Started)
Will need: BacklogView, BacklogViewModel, date grouping ("Today", "Yesterday", "This Week", "Older").

### Settings/ (Phase 3 — Not Started)
Will need: SettingsView, SettingsViewModel.

## Key Patterns
- **Views never call TaskService directly** — always through ViewModels.
- **No `@Query` in Views** — all data flows through ViewModels.
- **ViewModels are `@Observable @MainActor`** — synchronous TaskService calls (no async needed for CRUD).
- **Components take closures** for actions (`onToggleCompletion`, `onDelete`, etc.) — no direct ViewModel references.
- **Navigation via `AppCoordinator`** — accessed from environment, pushes `Route` values.

## Gotchas
- `RegionFocusView` handles both constrained regions (Morning/Afternoon/Evening with bucket sections) AND backlog (ungrouped list). This is fine for now but Week 3 should create a dedicated BacklogView with date grouping.
- `TaskEditSheet` is a private struct inside `RegionFocusView.swift`. If it's needed elsewhere, extract to `Shared/Components/`.
- Preview data uses `PreviewData.container` which creates a fresh in-memory container each time.
