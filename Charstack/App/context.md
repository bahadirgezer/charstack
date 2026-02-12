# App/ — Context for Next Session

## What's Here

### AppCoordinator.swift
`@Observable @MainActor` coordinator for app-wide navigation.
- `Tab` enum: `.today`, `.backlog`. Controls `selectedTab` for the TabView.
- `Route` enum: `.regionFocus(Region)`. Add more routes as screens are built (settings, task detail, etc.).
- `navigationPath: NavigationPath` — backs the Today tab's NavigationStack.
- Methods: `navigate(to:)`, `pop()`, `popToRoot()`, `showBacklog()`.
- Injected via `.environment(coordinator)` in RootView.

### RootView.swift
Root view of the app. Sets up the TabView with two tabs:
- **Today tab**: `NavigationStack(path: coordinator.navigationPath)` with `TodayView` and `.navigationDestination` for `Route` values.
- **Backlog tab**: Independent `NavigationStack` with `BacklogView`.

Contains `@Environment(\.scenePhase)` observer that triggers `performRolloverIfNeeded()` when app becomes active. Uses `@State private var lastRolloverDate: Date?` to prevent redundant same-day rollover calls.

**Important pattern:** `TaskService` is created as a computed property from `modelContext`. This is fine because `TaskService` is stateless — just a wrapper around `ModelContext`. If TaskService gains state, this needs to change.

## What Changed (Week 3)
- `AppCoordinator` gained `Tab` enum and `selectedTab` property for TabView.
- `RootView` rewritten from single NavigationStack to TabView with per-tab NavigationStacks.
- Added ScenePhase rollover observer with deduplication in RootView.
- `ContentView.swift` still exists in the project root with a deprecation comment. It's unused.

## Gotchas
- If `TaskService` gains state (e.g., caching), the computed property pattern in `RootView` won't work — you'd need to store it as `@State`.
- Each tab has its own NavigationStack. The coordinator's `navigationPath` only applies to the Today tab.
- Adding a Settings tab (Phase 3) should follow the same pattern: new `Tab` case + new tab in the TabView.
