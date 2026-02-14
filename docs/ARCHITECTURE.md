# Charflow Architecture Document

## Overview

Charflow is a minimal daily task manager for iOS designed with a focus on simplicity, productivity, and intentional work. Users organize tasks into 4 daily regions (Morning, Afternoon, Evening, Backlog) and apply the 1-3-5 rule per region: 1 must task, 3 complementary tasks, and 5 miscellaneous tasks.

This document outlines the complete technical architecture, design patterns, and implementation strategy for Charflow.

---

## 1. Technology Stack

### Platform & Language
- **Platform:** iOS 26+ (targets latest iOS features while maintaining reasonable backward compatibility)
- **Language:** Swift 6.0 (strict concurrency checking enabled)
- **Rationale:** Swift 6.0 provides actor-based concurrency guarantees, preventing data races at compile time. iOS 26+ allows use of latest SwiftUI features and optimizations.

### UI Framework
- **Primary:** SwiftUI 100% (no UIKit fallback)
- **Rationale:**
  - SwiftUI provides reactive, declarative UI composition
  - Native integration with Swift 6.0 concurrency model
  - Smaller app bundle and faster development iteration
  - State-driven UI updates align perfectly with MVVM pattern
  - Excellent performance for list-based task UI

### Persistence Layer
- **Primary:** SwiftData (Apple's modern data persistence framework)
- **Backup/Export:** JSON serialization for task export functionality
- **Rationale for SwiftData:**
  - Built on top of CloudKit infrastructure (future-proof for cloud sync)
  - Type-safe, compile-time checked Swift API (no stringly-typed queries)
  - Automatic migration support
  - Native SwiftUI integration with @Query macro
  - Significantly less boilerplate than CoreData
  - First-class support for UUIDs and enums

### Architecture Pattern
- **Primary:** MVVM (Model-View-ViewModel)
- **Supporting Patterns:** Service Layer, Coordinator (lightweight)
- **State Management:** @Observable and @Published macros (Swift 6.0)
- **Concurrency:** async/await throughout

### Testing Framework
- **Unit Tests:** Swift Testing (`@Suite`, `@Test`, `#expect`) — 86 tests, all passing
- **UI Tests:** XCTest (limited scope, future)
- **Test Data:** In-memory SwiftData containers
- **Preview Data:** `PreviewData.swift` — in-memory container with sample tasks for SwiftUI previews

### Build System
- **Build Tool:** Xcode 16.0+
- **Dependency Management:** Swift Package Manager (for future dependencies)

---

## 2. Architecture Pattern: MVVM

### Pattern Overview

Charstack implements Model-View-ViewModel (MVVM) pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────┐
│                    VIEW LAYER                   │
│  (SwiftUI Views - Declarative UI Components)    │
└────────────────────┬────────────────────────────┘
                     │
                     │ Binding / State Observation
                     │
┌────────────────────▼────────────────────────────┐
│              VIEWMODEL LAYER                    │
│  (@Observable / @Published State Management)    │
│  - TaskListViewModel                            │
│  - RegionViewModel                              │
│  - TaskDetailViewModel                          │
└────────────────────┬────────────────────────────┘
                     │
                     │ Dependency Injection
                     │
┌────────────────────▼────────────────────────────┐
│            SERVICE LAYER                        │
│  - TaskService (CRUD + Business Logic)          │
│  - DayRolloverService                           │
│  - NotificationService                          │
└────────────────────┬────────────────────────────┘
                     │
                     │ Data Access
                     │
┌────────────────────▼────────────────────────────┐
│           DATA LAYER (Models)                   │
│  - Task (SwiftData Model)                       │
│  - Region, TaskBucket, TaskStatus enums         │
│  - SwiftData container & schema                 │
└─────────────────────────────────────────────────┘
```

### Why MVVM?

1. **Reactive State Management:** SwiftUI's binding system naturally aligns with ViewModels holding @Observable state
2. **Testability:** Business logic in ViewModels can be unit tested without SwiftUI context
3. **Separation of Concerns:** UI logic separated from data persistence and business rules
4. **Scalability:** Easy to add new screens and features with consistent pattern
5. **Team Familiarity:** MVVM is well-understood and widely adopted in iOS development

### Alternatives Considered

#### The Composable Architecture (TCA)
- **Why Rejected:**
  - Introduces significant boilerplate for a simple task manager
  - Steep learning curve for team members
  - Overkill for apps without complex state synchronization needs
  - SwiftData's @Query macro already handles one-way data binding
  - TCA shines for complex reducer composition; Charstack doesn't need this

#### MVC (Traditional)
- **Why Rejected:**
  - Massive View Controller problem carries over to SwiftUI
  - No clear separation between UI logic and business logic
  - Difficult to unit test view controllers

#### Clean Architecture / VIPER
- **Why Rejected:**
  - Excessive layering for a focused single-purpose app
  - Coordination complexity not justified by scope

---

## 3. Project Structure

```
Charstack/
├── Charstack.xcodeproj
│   └── project.pbxproj
│
├── Charstack/                          # Main app source
│   ├── CharstackApp.swift              # @main entry point, ModelContainer setup
│   ├── ContentView.swift               # DEPRECATED — legacy placeholder (superseded by RootView)
│   │
│   ├── App/
│   │   ├── AppCoordinator.swift        # TabView + NavigationStack coordinator (Tab, Route enums)
│   │   └── RootView.swift              # Root view: TabView (Today + Backlog) + ScenePhase rollover
│   │
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── CharstackTask.swift     # SwiftData @Model — CloudKit-safe task model
│   │   │   ├── Region.swift            # Region enum (morning, afternoon, evening, backlog)
│   │   │   ├── TaskBucket.swift        # TaskBucket enum (must, complementary, misc, none)
│   │   │   ├── TaskStatus.swift        # TaskStatus enum (todo, inProgress, done, deferred)
│   │   │   └── BacklogDateGroup.swift  # Date grouping enum (today, yesterday, thisWeek, older)
│   │   │
│   │   ├── Services/
│   │   │   └── TaskService.swift       # CRUD, 1-3-5 enforcement, day rollover, grouped backlog queries
│   │   │
│   │   └── Persistence/
│   │       └── ModelContainerSetup.swift # Production + testing container factories
│   │
│   ├── Features/
│   │   ├── Today/
│   │   │   ├── TodayView.swift         # Main dashboard — 3 active region cards, daily progress
│   │   │   ├── TodayViewModel.swift    # State: tasks by active region, rollover, completion stats
│   │   │   └── Components/
│   │   │       └── RegionCard.swift    # Summary card: icon, must-do, counts, progress bar
│   │   │
│   │   ├── RegionFocus/
│   │   │   ├── RegionFocusView.swift   # Single-region task list grouped by bucket
│   │   │   ├── RegionFocusViewModel.swift # State: CRUD, capacity, edit sheet
│   │   │   └── Components/
│   │   │       ├── TaskRow.swift       # Task row: checkbox, title, badge, swipe/context
│   │   │       └── QuickAddBar.swift   # Inline task creation: title + bucket + add
│   │   │
│   │   ├── Backlog/
│   │   │   ├── BacklogView.swift       # Backlog tab — date-grouped task list with triage actions
│   │   │   └── BacklogViewModel.swift  # State: grouped tasks, move/edit/delete operations
│   │   │
│   │   └── Settings/                   # (Phase 3) User preferences
│   │
│   ├── Shared/
│   │   ├── Extensions/
│   │   │   └── Date+Extensions.swift   # Date helpers (startOfDay, endOfDay, etc.)
│   │   ├── Theme/
│   │   │   └── Theme.swift             # Colors, Typography, Spacing, CornerRadius
│   │   ├── Preview/
│   │   │   └── PreviewData.swift       # In-memory container + sample tasks for previews
│   │   └── Components/
│   │       ├── EmptyStateView.swift    # Reusable empty state with icon, title, subtitle
│   │       └── TaskEditSheet.swift     # Shared task edit sheet (title + notes)
│   │
│   └── Assets.xcassets
│
├── CharstackTests/                     # Unit tests (Swift Testing) — 86 tests
│   ├── Models/
│   │   ├── RegionTests.swift
│   │   ├── TaskBucketTests.swift
│   │   ├── TaskStatusTests.swift
│   │   ├── CharstackTaskTests.swift
│   │   └── BacklogDateGroupTests.swift # Date grouping, sorting, display names
│   │
│   ├── Services/
│   │   └── TaskServiceTests.swift      # CRUD, constraints, rollover, grouped backlog
│   │
│   ├── Extensions/
│   │   └── DateExtensionsTests.swift
│   │
│   └── CharstackTests.swift            # Smoke test
│
├── docs/
│   ├── ARCHITECTURE.md                 # This file
│   ├── PROJECT_BRIEF.md                # Original concept and vision
│   ├── REQUIREMENTS.md                 # Functional/non-functional + App Store compliance
│   └── ROADMAP.md                      # Development phases and milestones
│
└── README.md
```

### Directory Annotations

- **App/:** Application-level wiring — the coordinator pattern and root view.
- **Core/Models/:** SwiftData @Model classes and supporting enums. Business rules live at model level (computed properties, convenience methods) but enforcement is in Services.
- **Core/Services/:** Business logic layer — CRUD operations, 1-3-5 constraint validation, day rollover. ViewModels call Services; Views never call Services directly.
- **Core/Persistence/:** SwiftData ModelContainer configuration. Production (on-disk) and testing (in-memory) factories.
- **Features/:** Feature modules organized by screen — each contains Views, ViewModels, and Components subdirectories.
- **Shared/Extensions/:** Swift standard library extensions (Date helpers, etc.).
- **Shared/Theme/:** Centralized design tokens (colors, typography, spacing).
- **Shared/Preview/:** Preview helpers (sample data factory).
- **Shared/Components/:** (Week 3+) Reusable UI components shared across features.

---

## 4. Data Layer

### SwiftData Task Model — `CharstackTask`

> **Source of truth:** `Charstack/Core/Models/CharstackTask.swift`

The model uses raw `String` storage for enums (region, bucket, status) to ensure SwiftData
`#Predicate` compatibility, with typed computed accessors for ergonomic use in code.

```swift
@Model
final class CharstackTask {
    var identifier: UUID = UUID()       // No @Attribute(.unique) — CloudKit safe
    var title: String = ""
    var notes: String?
    var regionRawValue: String = "backlog"       // Stored as String for #Predicate
    var bucketRawValue: String = "none"
    var statusRawValue: String = "todo"
    var plannedDate: Date = Date()
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date?

    // Typed accessors (transient, not stored)
    var region: Region { get/set via regionRawValue }
    var bucket: TaskBucket { get/set via bucketRawValue }
    var status: TaskStatus { get/set via statusRawValue }
    var isOverdue: Bool { computed }

    // Convenience mutations
    func markCompleted()
    func markIncomplete()
    func deferToBacklog()
    func assignToRegion(_:bucket:)
}
```

### Enums

| Enum | Cases | Key Properties |
|------|-------|---------------|
| `Region` | morning, afternoon, evening, backlog | `displayName`, `systemImageName`, `isConstrained`, `sortOrder` |
| `TaskBucket` | must, complementary, misc, none | `maxCount` (1/3/5/∞), `displayName`, `sortOrder` |
| `TaskStatus` | todo, inProgress, done, deferred | `isIncomplete`, `countsTowardBucketLimit` |

### Key Data Design Decisions

1. **Raw String storage for enums:** SwiftData `#Predicate` doesn't support enum comparisons. Stored as raw strings with typed computed accessors.
2. **UUID `identifier` (not `id`):** Avoids conflict with SwiftData's implicit `id`. No `@Attribute(.unique)` for CloudKit compatibility.
3. **`plannedDate`:** Enables per-day constraint enforcement and future scheduling.
4. **`completedAt`:** Nullable timestamp — set on completion, cleared on revert. Enables future completion history.
5. **`deferred` status:** Distinct from `todo` — indicates the task was auto-rolled-over, not freshly created.
6. **No `autoCarry`/`isSticky`/`expiresAt` in MVP:** Deferred to Phase 2. Current rollover moves all incomplete active-region tasks to backlog unconditionally.

---

## 5. State Management

### ViewModel Pattern with @Observable

> **Source files:** `TodayViewModel.swift`, `RegionFocusViewModel.swift`

All ViewModels use `@Observable` + `@MainActor` for reactive state management. They receive `TaskService` via initializer injection — views never call `TaskService` or `@Query` directly.

```swift
@Observable
@MainActor
final class TodayViewModel {
    var tasksByRegion: [Region: [CharstackTask]] = [:]
    var isLoading = false
    var errorMessage: String?
    var rolledOverCount: Int?

    private let taskService: TaskService

    init(taskService: TaskService) { self.taskService = taskService }

    func loadTodaysTasks() { /* fetches from taskService, groups by region */ }
    func performDayRollover() { /* calls taskService.performDayRollover(), reloads */ }
    func toggleTaskCompletion(identifier: UUID) { /* delegates to taskService */ }
    func deleteTask(identifier: UUID) { /* delegates to taskService */ }

    // Computed: totalActiveTaskCount, completedActiveTaskCount, dailyCompletionFraction
}
```

```swift
@Observable
@MainActor
final class RegionFocusViewModel {
    let region: Region
    var tasks: [CharstackTask] = []
    var isLoading = false
    var errorMessage: String?
    var taskBeingEdited: CharstackTask?
    var isEditSheetPresented = false

    private let taskService: TaskService

    init(region: Region, taskService: TaskService) { ... }

    func loadTasks() { /* fetches for this region */ }
    func addTask(title:bucket:) { /* creates via taskService */ }
    func toggleTaskCompletion(identifier:) { ... }
    func deleteTask(identifier:) { ... }
    func updateTask(identifier:title:notes:) { ... }
    func moveTask(identifier:toRegion:bucket:) { ... }
    func remainingCapacity(for bucket:) -> Int { ... }
}
```

### Key State Management Principles

1. **@Observable:** Native Swift 6.0 observable macro; no third-party dependencies
2. **@MainActor on ViewModels:** Ensures all state mutations happen on main thread; matches `TaskService`'s actor isolation
3. **Synchronous TaskService calls:** `TaskService` methods are synchronous (SwiftData writes are sync), so ViewModels call them directly — no `async/await` needed for CRUD
4. **Error as String:** `errorMessage: String?` drives alert presentation via SwiftUI `.alert(isPresented:)`
5. **No @Query in Views:** All data flows through ViewModel → TaskService, keeping data access consistent and testable

### ViewModel Layer Responsibilities

- **Hold View State:** isLoading, error, selectedItem, filters, etc.
- **Fetch Data:** Call services, handle async operations
- **Business Logic:** Filtering, sorting, validation
- **Handle User Actions:** Create, update, delete task commands
- **Drive UI Updates:** State changes trigger SwiftUI view redraws

---

## 6. Service Layer

### TaskService

> **Source of truth:** `Charstack/Core/Services/TaskService.swift`

`TaskService` is `@MainActor` (not an actor) because SwiftData's `ModelContext` is not `Sendable`.
It owns all CRUD operations, 1-3-5 constraint enforcement, and day rollover logic.

**Key API surface:**

| Method | Purpose |
|--------|---------|
| `createTask(_:)` | Insert task after validating title + bucket capacity |
| `fetchTasks(for:in:)` | Tasks for a date, optionally filtered by region |
| `fetchBacklogTasks()` | All backlog tasks, newest first |
| `fetchGroupedBacklogTasks()` | Backlog tasks grouped by date (Today/Yesterday/This Week/Older) |
| `fetchTask(byIdentifier:)` | Single task lookup |
| `updateTaskContent(identifier:title:notes:)` | Edit title/notes |
| `moveTask(identifier:toRegion:bucket:)` | Move with constraint check at destination |
| `toggleTaskCompletion(identifier:)` | Toggle done/todo |
| `updateTaskSortOrder(identifier:newSortOrder:)` | Reorder within bucket |
| `deleteTask(identifier:)` | Permanent deletion |
| `countActiveTasks(in:bucket:on:)` | Active task count for constraint queries |
| `remainingCapacity(in:bucket:on:)` | How many more tasks can be added |
| `performDayRollover()` | Batch move overdue incomplete tasks → backlog (idempotent) |

**Error types:** `TaskServiceError` — `.bucketFull`, `.taskNotFound`, `.emptyTitle`, `.invalidOperation`

### Day Rollover (integrated into TaskService)

Day rollover is a method on `TaskService`, not a separate service. It:
1. Finds all tasks planned before today in active regions (morning/afternoon/evening) with status todo or inProgress.
2. Calls `deferToBacklog()` on each — sets region=backlog, bucket=none, status=deferred.
3. Is idempotent — calling twice is safe (already-deferred tasks are filtered out).
4. Returns the count of tasks moved.

### NotificationService (Phase 3)

Not implemented in MVP. Will handle local notifications via `UNUserNotificationCenter`.

---

## 7. Navigation

### TabView + Coordinator Pattern

> **Source of truth:** `Charstack/App/AppCoordinator.swift`, `Charstack/App/RootView.swift`

Charstack uses a TabView with two tabs (Today, Backlog) and a lightweight Coordinator pattern for in-tab navigation. The coordinator is `@Observable` and `@MainActor`, injected into the SwiftUI environment:

```swift
@Observable
@MainActor
final class AppCoordinator {
    enum Tab: Hashable {
        case today
        case backlog
    }

    enum Route: Hashable {
        case regionFocus(Region)
    }

    var selectedTab: Tab = .today
    var navigationPath = NavigationPath()  // For Today tab's NavigationStack

    func navigate(to route: Route) { navigationPath.append(route) }
    func pop() { ... }
    func popToRoot() { ... }
    func showBacklog() { selectedTab = .backlog }
}
```

### RootView Structure

```swift
struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("Today", systemImage: "sun.max", value: .today) {
                NavigationStack(path: $coordinator.navigationPath) {
                    TodayView(...)
                        .navigationDestination(for: AppCoordinator.Route.self) { ... }
                }
            }
            Tab("Backlog", systemImage: "tray", value: .backlog) {
                NavigationStack {
                    BacklogView(...)
                }
            }
        }
        .environment(coordinator)
        .onChange(of: scenePhase) { /* trigger rollover on foreground */ }
    }
}
```

### Navigation Design Decisions

1. **TabView for top-level screens:** Today and Backlog are peer-level features, not parent-child
2. **Per-tab NavigationStack:** Each tab has its own navigation hierarchy
3. **Route enum:** Type-safe navigation within the Today tab — extensible for future screens
4. **Lightweight Coordinator:** Avoids complex routing libraries; adds minimal overhead
5. **Deep Linking Ready:** Route enum + Tab enum enables future universal link support
6. **Environment injection:** Coordinator passed via `.environment()` so child views don't need explicit references
7. **ScenePhase observer:** RootView monitors `scenePhase` to trigger day rollover on foreground return

---

## 8. Testing Strategy

### Testing Pyramid

```
        /\
       /  \  UI Tests (Minimal)
      /____\
     /      \  Integration Tests
    /________\
   /          \ Unit Tests (Priority)
  /____________\
```

### Unit Tests (Priority)

Focus on Service layer and ViewModel logic:

```swift
import XCTest
@testable import Charstack

final class TaskServiceTests: XCTestCase {
    var sut: TaskService!
    var container: ModelContext!

    override func setUp() {
        super.setUp()
        container = ModelContext(ModelConfiguration(isStoredInMemoryOnly: true))
        sut = TaskService(container: container)
    }

    func testCreateTaskEnforcesOneRuleBucket() async throws {
        let mustTask1 = Task(title: "Task 1", region: .morning, bucket: .must)
        let mustTask2 = Task(title: "Task 2", region: .morning, bucket: .must)

        try sut.createTask(mustTask1)

        // Second must task should fail
        XCTAssertThrowsError(try sut.createTask(mustTask2)) { error in
            if case .bucketFull(.must) = error as? TaskServiceError {
                // Expected
            } else {
                XCTFail("Expected bucketFull error")
            }
        }
    }

    func testFetchTasksFiltersCorrectly() async throws {
        let today = Date().startOfDay
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let task1 = Task(title: "Today", plannedDate: today)
        let task2 = Task(title: "Tomorrow", plannedDate: tomorrow)

        try sut.createTask(task1)
        try sut.createTask(task2)

        let todaysTasks = try sut.fetchTasks(for: today)
        XCTAssertEqual(todaysTasks.count, 1)
        XCTAssertEqual(todaysTasks.first?.title, "Today")
    }

    func testTaskAutoCarry() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date().startOfDay)!
        let task = Task(title: "Unfinished", plannedDate: yesterday, autoCarry: true)

        try sut.createTask(task)
        let rolloverService = DayRolloverService(taskService: sut, container: container)
        try await rolloverService.performDayRollover()

        let todaysTasks = try sut.fetchTasks(for: Date().startOfDay)
        XCTAssertTrue(todaysTasks.contains { $0.title == "Unfinished" })
    }
}
```

### ViewModel Tests

```swift
final class TaskListViewModelTests: XCTestCase {
    var sut: TaskListViewModel!
    var mockTaskService: MockTaskService!

    override func setUp() {
        super.setUp()
        mockTaskService = MockTaskService()
        sut = TaskListViewModel(taskService: mockTaskService)
    }

    func testLoadTodaysTasks() async {
        mockTaskService.tasksToReturn = [
            Task(title: "Task 1"),
            Task(title: "Task 2")
        ]

        await sut.loadTodaysTasks()

        XCTAssertEqual(sut.tasks.count, 2)
        XCTAssertFalse(sut.isLoading)
    }

    func testErrorHandling() async {
        mockTaskService.shouldThrowError = true

        await sut.loadTodaysTasks()

        XCTAssertNotNil(sut.error)
    }
}
```

### UI Tests (Minimal Scope)

Focus on critical user workflows:

```swift
final class TaskListUITests: XCTestCase {
    func testCreateTaskFlow() {
        let app = XCUIApplication()
        app.launch()

        // Navigate to create task
        app.buttons["Add Task"].tap()

        // Fill form
        let titleField = app.textFields["Task Title"]
        titleField.tap()
        titleField.typeText("Test Task")

        // Submit
        app.buttons["Create"].tap()

        // Verify task appears
        XCTAssertTrue(app.staticTexts["Test Task"].exists)
    }
}
```

### Test Data & Mocking

- **In-Memory Container:** SwiftData supports `isStoredInMemoryOnly` for testing
- **Mock Services:** Create MockTaskService for ViewModel tests
- **Preview Data:** Use PreviewData.swift for SwiftUI previews and UI tests

### Testing Metrics

- **Target Coverage:** 80%+ for Services, 70%+ for ViewModels
- **UI Test Coverage:** Critical paths only (create, edit, complete)
- **Regression Tests:** One test per fixed bug

---

## 9. Key Design Decisions

### Decision 1: SwiftData over CoreData

**Decision:** Use SwiftData as primary persistence framework

**Rationale:**
- Native Swift API without stringly-typed queries
- Compile-time type safety with #Predicate
- Automatic model versioning
- Better integration with SwiftUI (@Query macro)
- Significantly less boilerplate code
- Built on CloudKit infrastructure (future-proof)

**Trade-offs:**
- Requires iOS 26+ (acceptable for new app)
- Smaller ecosystem than CoreData
- Mitigation: Fallback to JSON export for compatibility

**Related:** Considered using Realm, but SwiftData's native status and iOS 26+ support won out

---

### Decision 2: CloudKit-First, BaaS Later

**Decision:** Cloud sync strategy is phased: local-only MVP, then CloudKit native integration, then optional BaaS for accounts.

**Phase 1 (MVP):** Local SwiftData only. No sync, no accounts.

**Phase 2:** Add CloudKit via SwiftData's native integration. Near-zero code — just add iCloud capability, Background Modes (Remote Notifications), and ensure all model properties have defaults or are optional. This gives automatic device sync for the same Apple ID. No user accounts, no backend.

**Phase 3+:** Add a Backend-as-a-Service (Firebase or Supabase) for proper user accounts (Sign in with Apple + Google), cross-device sync beyond iCloud, and user management. This layer sits alongside CloudKit, not replacing it.

**Rationale:**
- CloudKit is free, native, and requires almost no code with SwiftData
- SwiftData models must follow CloudKit rules: no @Attribute(.unique), all properties must have defaults or be optional, all relationships must be optional
- BaaS deferred until accounts are actually needed — avoids premature complexity
- Architecture is designed so TaskService can be extended with sync methods without refactoring

**Trade-offs:**
- Phase 2 is Apple-only (no Android/web sync)
- Phase 3 adds a third-party dependency (Firebase/Supabase SDK)
- Account features trigger App Store requirements (account deletion, Sign in with Apple, privacy policy)

**Future Scalability:** When adding cloud sync, extend existing TaskService with CloudKit methods without refactoring core logic

---

### Decision 3: Local Notifications Only (No Remote Push)

**Decision:** Initial implementation uses only local/scheduled notifications via UNUserNotificationCenter

**Rationale:**
- Eliminates need for APNs, backend infrastructure, certificates in MVP
- Local notifications are sufficient for daily task reminders
- Users maintain full control and privacy
- Simpler to implement and test

**Trade-offs:**
- No server-triggered urgent notifications
- No real-time activity from other devices (irrelevant for single-user tasks app)

**Future Path:** Add APNs when implementing cloud features (v2+)

---

### Decision 4: No Task Dependencies in MVP

**Decision:** Exclude task blocking/dependency features from v1

**Rationale:**
- 1-3-5 rule doesn't require dependencies; tasks are independent
- Dependencies add significant data model and UI complexity
- Increases test surface area substantially
- Can implement later without breaking data model
- Most users don't manage task dependencies daily

**Deferred to Phase 2:**
- `autoCarry`: Automatic carryover to same region next day (instead of backlog)
- `isSticky`: Force task to top of region
- `expiresAt`: Auto-delete from backlog after expiration
- Current MVP rollover moves ALL incomplete active-region tasks to backlog unconditionally

**Future Enhancement:** Add optional "blockedBy" field and task graph traversal in v2 if user research validates need

---

### Decision 5: SwiftUI-Only (No UIKit)

**Decision:** 100% SwiftUI; no UIKit fallback components

**Rationale:**
- iOS 26+ baseline allows full SwiftUI feature set
- SwiftUI's declarative model maps perfectly to MVVM
- Faster iteration and preview-driven development
- Smaller codebase (no dual implementations)
- Better performance for list-heavy UIs

**Trade-offs:**
- Cannot target iOS 16 or earlier
- Some custom components may require workarounds (acceptable)
- Dependency on Apple's continued SwiftUI investment (justified)

**Implementation:** SwiftUI 4.0+ (available on iOS 26+); use modifiers over legacy apis

---

## 10. Performance Considerations

### List Rendering Optimization

```swift
// Use LazyVStack for large task lists to defer rendering
LazyVStack(spacing: 8) {
    ForEach(tasks, id: \.id) { task in
        TaskRowView(task: task)
    }
}

// Identify stable keys for ForEach to minimize redraws
ForEach(tasks, id: \.id) { task in // id is UUID, stable across updates
    TaskRowView(task: task)
}
```

### Database Query Optimization

1. **Limit Query Results:** Fetch only today's tasks, not entire database
2. **Index Fields:** SwiftData indexes id, plannedDate, region for fast queries
3. **Batch Operations:** Use transaction-like patterns for multiple writes
4. **Lazy Loading:** Load task details on-demand, not all at once

### Memory Management

- **@State vs @Bindable:** Use @State for view-local state, @Observable for shared state
- **Task Cancellation:** Cancel ongoing fetches when view disappears
- **Image Assets:** Avoid loading large assets; use vector graphics where possible

### Startup Performance

- **Lazy Initialization:** Services created on-demand, not eagerly
- **Warm Cache:** Pre-fetch today's tasks while app boots
- **Async Loading:** Don't block UI on data fetch; show loading state

### Example: Optimized TaskListView

```swift
struct TaskListView: View {
    @State var viewModel: TaskListViewModel
    @Query(sort: \.plannedDate, order: .forward) var tasks: [Task]

    var body: some View {
        List {
            ForEach(Region.allCases, id: \.self) { region in
                let regionTasks = tasks.filter { $0.region == region }
                RegionView(region: region, tasks: regionTasks)
            }
        }
        .task {
            // Load on appearance, but @Query handles ongoing updates
            await viewModel.loadTodaysTasks()
        }
    }
}
```

---

## 11. Security & Privacy

### Data Protection

- **Local Storage:** All task data stored locally in encrypted SwiftData container
- **No Network:** No data transmitted externally (MVP phase)
- **Encryption at Rest:** iOS automatically encrypts app container with device PIN/FaceID
- **No Passwords:** No authentication in MVP; single-user device context

### User Privacy

1. **Local-First:** Tasks never leave device without explicit user action
2. **Manual Export:** Users control if/when data is exported
3. **No Analytics:** No analytics or crash reporting (MVP)
4. **No Ads:** No advertising, no third-party SDKs

### Future Considerations (v2+)

- **CloudKit Sync (Phase 2):** End-to-end encrypted via iCloud private database; native SwiftData integration
- **Authentication (Phase 3):** Sign in with Apple (mandatory if any third-party login offered) + Google Sign-In via Firebase/Supabase
- **Account Deletion (Phase 3):** Required by App Store Guideline 5.1.1(v) — must delete all user data and revoke Sign in with Apple tokens
- **Privacy Policy (Phase 3):** Required in-app and in App Store Connect
- **Privacy Nutrition Labels (Phase 3):** Must accurately declare all data collected

### Security Best Practices

- **Input Validation:** Validate task titles and notes (length, characters)
- **Dependency Management:** Minimal external dependencies; vet all packages
- **Code Signing:** Official Apple developer account required for distribution
- **Secure Coding:** Swift's memory safety; no unsafe code except where documented

---

## 12. Future Scalability

### Potential Enhancements (Post-MVP)

#### Phase 2: CloudKit Sync
- Add CloudKit via SwiftData's native integration (iCloud capability, Background Modes)
- Automatic device sync for same Apple ID — no user accounts required
- Extend TaskService with sync methods
- New SyncViewModel to manage sync state

#### Phase 3: User Accounts & BaaS
- Add Sign in with Apple + Google Sign-In via Firebase or Supabase
- Cross-device sync beyond iCloud (Android, web support)
- Account deletion functionality (App Store Guideline 5.1.1(v) mandatory)
- Privacy policy in-app and in App Store Connect
- Privacy Nutrition Labels for data collection declarations

#### Phase 4: Collaboration
- Share task lists with other users (read-only or edit)
- Per-task comments and mentions
- Activity log of task changes
- Requires role-based access control

#### Phase 5: Advanced Features
- **Recurring Tasks:** Pattern-based task generation (daily, weekly, etc)
- **Task Dependencies:** Block tasks on others; prerequisite logic
- **Analytics:** Weekly review of completion rates, trends
- **Integrations:** IFTTT, Shortcuts, calendar sync

#### Phase 6: Multi-Platform
- **macOS:** Mac Catalyst or native SwiftUI app
- **Web:** CloudKit-backed web dashboard
- **Watch:** Minimal watch app for quick check-in

### Architectural Readiness

**Designed for Scaling:**
- Service layer abstraction enables feature flags and A/B tests
- MVVM keeps business logic testable as complexity grows
- SwiftData schema supports additive migrations without breaking
- Coordinator pattern allows deep linking and complex navigation
- Unit test foundation prevents regressions during refactoring

**Anti-Patterns to Avoid:**
- Don't couple ViewModels directly to Views (use protocols if needed)
- Don't add business logic to Views; keep it in Services
- Don't skip tests as features grow; regression test count scales with code
- Don't create mega-ViewModels; split by feature/screen

---

## Summary

Charstack's architecture prioritizes:

1. **Simplicity** — MVVM + Services, no over-engineering
2. **Testability** — Strong unit test suite from day one
3. **Performance** — Optimized list rendering, efficient queries
4. **Privacy** — Local-first, explicit data sharing
5. **Scalability** — Foundation for cloud, collaboration, multi-platform

The combination of Swift 6.0, SwiftUI, SwiftData, and a clean MVVM pattern provides a solid foundation for a focused daily task manager that can grow thoughtfully as user needs evolve.
