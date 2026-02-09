# Features/ — Context for Next Session

## What's Here
Feature modules organized by screen. Each feature has its own View, ViewModel, and Components/ subdirectory.

### Today/ (Complete — Week 2, updated Week 3)
- **TodayView.swift** — Main dashboard. ScrollView with 3 RegionCards (Morning/Afternoon/Evening only — backlog is now a separate tab), daily progress bar, rollover banner, empty state using shared `EmptyStateView`. Uses `TodayViewModel`.
- **TodayViewModel.swift** — `@Observable @MainActor`. Holds `tasksByRegion: [Region: [CharstackTask]]` for active regions only. Loads today's tasks, triggers day rollover, tracks completion stats. All data flows through `TaskService`.
- **Components/RegionCard.swift** — Summary card per region. Shows icon, must-do title (or placeholder), bucket fill counts, progress bar. Tapping calls `onTap` closure which navigates via coordinator.

### RegionFocus/ (Complete — Week 2, updated Week 3)
- **RegionFocusView.swift** — Detailed view for a single region. For constrained regions, shows tasks grouped into Must-Do/Complementary/Misc sections with QuickAddBar. For backlog, shows ungrouped list with "Move to..." context menu. Uses shared `EmptyStateView` and `TaskEditSheet`.
- **RegionFocusViewModel.swift** — `@Observable @MainActor`. Holds tasks for a single region. CRUD via TaskService. Tracks edit sheet state.
- **Components/TaskRow.swift** — Single task row. Checkbox (with `contentTransition(.symbolEffect(.replace))`), title (strikethrough on done), notes preview, bucket badge. Swipe actions: complete (leading), delete (trailing). Context menu: edit, move, delete. **No ViewModel** — intentionally a pure display component (see design note in file).
- **Components/QuickAddBar.swift** — Inline task creation bar. Text field + bucket picker (Menu) + add button. Defaults to Misc bucket.

### Backlog/ (Complete — Week 3)
- **BacklogView.swift** — Dedicated backlog tab with date-grouped sections (Today/Yesterday/This Week/Older). Each section has group header with icon, name, and task count. Tasks have context menus: Edit, Move to... (with region > bucket sub-menus), Delete. Uses shared `EmptyStateView` and `TaskEditSheet`.
- **BacklogViewModel.swift** — `@Observable @MainActor`. Holds `groupedTasks: [(group: BacklogDateGroup, tasks: [CharstackTask])]`. Loads via `TaskService.fetchGroupedBacklogTasks()`. Supports move, toggle, delete, edit operations.

### Settings/ (Phase 3 — Not Started)
Will need: SettingsView, SettingsViewModel.

## Key Patterns
- **Views never call TaskService directly** — always through ViewModels.
- **No `@Query` in Views** — all data flows through ViewModels.
- **ViewModels are `@Observable @MainActor`** — synchronous TaskService calls (no async needed for CRUD).
- **Components take closures** for actions (`onToggleCompletion`, `onDelete`, etc.) — no direct ViewModel references.
- **Navigation via `AppCoordinator`** — accessed from environment, pushes `Route` values (Today tab only).
- **Shared components** for cross-feature UI: `EmptyStateView`, `TaskEditSheet` in `Shared/Components/`.

## Gotchas
- `RegionFocusView` still handles both constrained regions and backlog display (when navigated to from Today tab pre-Week 3). The dedicated `BacklogView` is now the primary backlog interface via the Backlog tab.
- Preview data uses `PreviewData.container` which creates a fresh in-memory container each time.
- BacklogView's move-to-region menu only shows `Region.activeRegions` (not backlog-to-backlog).
