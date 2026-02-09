# CharstackTests/ — Context for Next Session

## What's Here
Unit tests using **Swift Testing** framework (`@Suite`, `@Test`, `#expect`), not XCTest.

### Test Structure
- `Models/` — Tests for Region, TaskBucket, TaskStatus enums, CharstackTask model, and BacklogDateGroup
- `Services/` — TaskServiceTests with CRUD, constraint enforcement, day rollover, grouped backlog
- `Extensions/` — Date+Extensions tests
- `CharstackTests.swift` — Smoke test (placeholder from Xcode template)

### How Tests Work
- Each test creates its own `TaskService` with a fresh in-memory `ModelContainer` via `ModelContainerSetup.createTestingContainer()`.
- `TaskServiceTests` is `@MainActor` because `TaskService` is `@MainActor`.
- The `makeTask()` helper provides sensible defaults for test task creation.

### Test Count: 86 tests, all passing
- RegionTests: 7
- TaskBucketTests: 7
- TaskStatusTests: 5
- CharstackTaskTests: 12
- TaskServiceTests: 29 (includes rollover idempotency, per-region constraints, per-day constraints, 3 grouped backlog tests)
- DateExtensionsTests: 7
- BacklogDateGroupTests: 7 (today/yesterday/this week/older grouping, sorting, display names, system images)
- CharstackTests: 1 (smoke test)
- Other model and service test helpers contribute remaining count

### What Changed (Week 3)
- Added `BacklogDateGroupTests.swift` (7 tests) — tests for relative date grouping logic
- Added 3 tests to `TaskServiceTests` — `fetchGroupedBacklogTasksGroupsByDate`, `fetchGroupedBacklogTasksReturnsEmptyWhenNoBacklog`, `fetchGroupedBacklogTasksExcludesNonBacklog`
- Test count went from ~48 to 86

### What's Not Tested
- ViewModel tests (TodayViewModel, RegionFocusViewModel, BacklogViewModel — consider adding in Week 4 or Phase 2)
- UI tests (no XCUITest yet)
- Performance benchmarks
- Edge cases: very large task counts, timezone transitions
- BacklogDateGroup's `thisWeek` test gracefully skips on Mondays (not enough days into the week to test "earlier this week")
