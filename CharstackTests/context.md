# CharstackTests/ — Context

## What's Here
Unit tests using **Swift Testing** framework (`@Suite`, `@Test`, `#expect`), not XCTest.

### Test Structure
- `Models/` — Tests for Region, TaskBucket, TaskStatus enums and CharstackTask model
- `Services/` — TaskServiceTests with CRUD, constraint enforcement, day rollover
- `Extensions/` — Date+Extensions tests
- `CharstackTests.swift` — Smoke test (placeholder from Xcode template)

### How Tests Work
- Each test creates its own `TaskService` with a fresh in-memory `ModelContainer` via `ModelContainerSetup.createTestingContainer()`.
- `TaskServiceTests` is `@MainActor` because `TaskService` is `@MainActor`.
- The `makeTask()` helper provides sensible defaults for test task creation.

### Test Count: 38 tests, all passing
- RegionTests: 7
- TaskBucketTests: 7
- TaskStatusTests: 5
- CharstackTaskTests: 12
- TaskServiceTests: 26 (includes rollover idempotency, per-region constraints, per-day constraints)
- DateExtensionsTests: 7

### What's Not Tested
- UI/ViewModel tests (no ViewModels yet — Week 2)
- Performance benchmarks
- Edge cases: very large task counts, timezone transitions
