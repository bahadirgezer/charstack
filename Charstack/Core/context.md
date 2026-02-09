# Core/ — Context for Next Session

## What's Here
The `Core/` directory contains the data layer and business logic for Charstack. No UI code lives here.

### Models/
- **CharstackTask.swift** — The primary SwiftData `@Model`. CloudKit-safe: no `@Attribute(.unique)`, all properties have defaults. Enums stored as raw `String` values for `#Predicate` compatibility, with typed computed accessors.
- **Region.swift** — `morning`, `afternoon`, `evening`, `backlog`. Has `activeRegions` static property (excludes backlog). Active regions enforce 1-3-5; backlog is unconstrained.
- **TaskBucket.swift** — `must` (max 1), `complementary` (max 3), `misc` (max 5), `unassigned` (unconstrained). Has `constrainedBuckets` static property.
- **TaskStatus.swift** — `todo`, `inProgress`, `done`, `deferred`. Only `todo`/`inProgress` count toward bucket limits.
- **BacklogDateGroup.swift** — `today`, `yesterday`, `thisWeek`, `older`. Groups backlog tasks by relative date via `group(for:)` static method. Conforms to `Comparable` for sort ordering. Used by `TaskService.fetchGroupedBacklogTasks()`.

### Services/
- **TaskService.swift** — `@MainActor` class that owns all CRUD and business logic. Validates title (non-empty) and 1-3-5 constraints before insert/move. Includes `performDayRollover()` for batch moving overdue incomplete tasks to backlog. Has `fetchGroupedBacklogTasks()` for date-grouped backlog queries.

### Persistence/
- **ModelContainerSetup.swift** — Factory for production (on-disk) and testing (in-memory) `ModelContainer` instances. The schema registers `CharstackTask` as the sole model type.

## Key Design Decisions
1. **Raw string enum storage:** SwiftData `#Predicate` can't compare enums. Stored as strings, accessed via computed properties.
2. **`@MainActor` not `actor`:** `ModelContext` isn't `Sendable`, so TaskService must run on main actor.
3. **Day rollover is on TaskService:** No separate `DayRolloverService` — simpler with shared `ModelContext`.
4. **`deferred` status:** Distinguishes rolled-over tasks from fresh backlog items.
5. **Grouped backlog in service layer:** `fetchGroupedBacklogTasks()` groups at the service level using `BacklogDateGroup.group(for:)`, not in the ViewModel. This keeps grouping logic reusable and testable.

## Consumers
- **TodayViewModel** — Calls `fetchTasks(for:in:)` for active regions only, `performDayRollover()`, `toggleTaskCompletion()`, `deleteTask()`
- **RegionFocusViewModel** — Calls `createTask()`, `fetchTasks(for:in:)`, `toggleTaskCompletion()`, `deleteTask()`, `updateTaskContent()`, `moveTask()`, `remainingCapacity()`
- **BacklogViewModel** — Calls `fetchGroupedBacklogTasks()`, `moveTask()`, `toggleTaskCompletion()`, `deleteTask()`, `updateTaskContent()`
- Views never call TaskService directly — always through ViewModels.

## Consumers
- **TodayViewModel** — Calls `fetchTasks(for:in:)`, `fetchBacklogTasks()`, `performDayRollover()`, `toggleTaskCompletion()`, `deleteTask()`
- **RegionFocusViewModel** — Calls `createTask()`, `fetchTasks(for:in:)`, `toggleTaskCompletion()`, `deleteTask()`, `updateTaskContent()`, `moveTask()`, `remainingCapacity()`
- Views never call TaskService directly — always through ViewModels.

## What's Not Done
- No `NotificationService` (Phase 3)
- No `BackupService` (future)
- No migration strategy yet (will be needed when schema changes)
- No `CalendarService` (Phase 2 — read-only EventKit integration)
