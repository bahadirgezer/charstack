# App/ — Context for Next Session

## What's Here

### AppCoordinator.swift
`@Observable @MainActor` coordinator for NavigationStack-based navigation.
- `Route` enum: currently only `.regionFocus(Region)`. Add more routes as screens are built (settings, task detail, etc.).
- `navigationPath: NavigationPath` — backs the NavigationStack.
- Methods: `navigate(to:)`, `pop()`, `popToRoot()`.
- Injected via `.environment(coordinator)` in RootView.

### RootView.swift
Root view of the app. Creates the coordinator, gets `modelContext` from environment, creates `TaskService`, sets up NavigationStack with destination mapping. This is where new `Route` cases get their view mapping.

**Important pattern:** `TaskService` is created as a computed property from `modelContext`. This means a new instance is created each time the body is evaluated, but that's fine because `TaskService` is stateless — it's just a thin wrapper around `ModelContext`.

## What Changed (Week 2)
- `CharstackApp.swift` was updated to use `RootView()` instead of `ContentView()`.
- `ContentView.swift` still exists in the project root but is unused. Should be deleted in Week 3.

## Gotchas
- If `TaskService` gains state (e.g., caching), the computed property pattern in `RootView` won't work — you'd need to store it as `@State`.
- When adding a TabView (Week 3?), the coordinator pattern may need adjustment — each tab might need its own NavigationStack, or a single coordinator could manage multiple paths.
