# Charstack Architecture Document

## Overview

Charstack is a minimal daily task manager for iOS designed with a focus on simplicity, productivity, and intentional work. Users organize tasks into 4 daily regions (Morning, Afternoon, Evening, Backlog) and apply the 1-3-5 rule per region: 1 must task, 3 complementary tasks, and 5 miscellaneous tasks.

This document outlines the complete technical architecture, design patterns, and implementation strategy for Charstack.

---

## 1. Technology Stack

### Platform & Language
- **Platform:** iOS 17+ (targets latest iOS features while maintaining reasonable backward compatibility)
- **Language:** Swift 6.0 (strict concurrency checking enabled)
- **Rationale:** Swift 6.0 provides actor-based concurrency guarantees, preventing data races at compile time. iOS 17+ allows use of latest SwiftUI features and optimizations.

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
- **Unit Tests:** XCTest
- **UI Tests:** XCTest (limited scope)
- **Test Data:** In-memory SwiftData containers

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
├── Charstack/
│   ├── App/
│   │   ├── CharstackApp.swift           # App entry point, SwiftData container setup
│   │   └── AppCoordinator.swift         # Navigation routing
│   │
│   ├── Models/
│   │   ├── Task.swift                   # SwiftData Task model + enums
│   │   ├── Region.swift                 # Region enum (morning, afternoon, evening, backlog)
│   │   ├── TaskBucket.swift             # TaskBucket enum (must, complementary, misc, none)
│   │   └── TaskStatus.swift             # TaskStatus enum (todo, doing, done)
│   │
│   ├── Services/
│   │   ├── TaskService.swift            # CRUD operations, 1-3-5 rule enforcement
│   │   ├── DayRolloverService.swift     # Automatic daily reset logic
│   │   ├── NotificationService.swift    # Local notification management
│   │   └── BackupService.swift          # JSON export/import (future)
│   │
│   ├── ViewModels/
│   │   ├── TaskListViewModel.swift      # Main task grid, region management
│   │   ├── RegionViewModel.swift        # Per-region task management
│   │   ├── TaskDetailViewModel.swift    # Task editing and creation
│   │   ├── TaskEditViewModel.swift      # Task creation/editing form
│   │   └── AppRootViewModel.swift       # App-wide state
│   │
│   ├── Views/
│   │   ├── RootView.swift               # App root, navigation setup
│   │   │
│   │   ├── TaskList/
│   │   │   ├── TaskListView.swift       # Main 4-region grid layout
│   │   │   ├── RegionView.swift         # Individual region container
│   │   │   ├── TaskRowView.swift        # Single task cell
│   │   │   └── TaskCardView.swift       # Task card with drag support
│   │   │
│   │   ├── TaskDetail/
│   │   │   ├── TaskDetailView.swift     # Task view with editing options
│   │   │   └── TaskDetailEditView.swift # Inline or sheet editing
│   │   │
│   │   ├── TaskForm/
│   │   │   ├── TaskFormView.swift       # Reusable form (create/edit)
│   │   │   ├── TaskTitleField.swift
│   │   │   ├── TaskNotesField.swift
│   │   │   ├── RegionSelector.swift
│   │   │   ├── BucketSelector.swift
│   │   │   └── StatusToggle.swift
│   │   │
│   │   ├── Components/
│   │   │   ├── RegionHeader.swift       # Region title with 1-3-5 indicator
│   │   │   ├── TaskCountBadge.swift     # Visual count for each bucket
│   │   │   ├── EmptyStateView.swift
│   │   │   ├── LoadingView.swift
│   │   │   └── ConfirmationDialog.swift
│   │   │
│   │   └── Settings/
│   │       ├── SettingsView.swift       # App settings (theme, notifications, etc)
│   │       └── ExportView.swift         # Task export as JSON
│   │
│   ├── Utilities/
│   │   ├── DateHelper.swift             # Date manipulation, day boundaries
│   │   ├── Constants.swift              # App-wide constants
│   │   ├── Extensions.swift             # Swift stdlib extensions
│   │   └── Logging.swift                # Structured logging helper
│   │
│   ├── Resources/
│   │   ├── Localizable.strings          # String localization
│   │   ├── Colors.xcassets
│   │   ├── Fonts.xcassets
│   │   └── AppIcon.appiconset
│   │
│   └── Preview Content/
│       ├── PreviewData.swift            # Mock tasks for previews
│       └── Preview Assets/
│
├── CharstackTests/
│   ├── Services/
│   │   ├── TaskServiceTests.swift       # CRUD, validation, 1-3-5 enforcement tests
│   │   ├── DayRolloverServiceTests.swift
│   │   └── NotificationServiceTests.swift
│   │
│   ├── ViewModels/
│   │   ├── TaskListViewModelTests.swift
│   │   └── TaskDetailViewModelTests.swift
│   │
│   ├── Models/
│   │   └── TaskModelTests.swift         # Model validation, computed properties
│   │
│   └── Utilities/
│       └── DateHelperTests.swift
│
├── CharstackUITests/
│   ├── TaskListUITests.swift            # Navigation, task creation flow
│   └── TaskDetailUITests.swift
│
├── docs/
│   ├── ARCHITECTURE.md                  # This file
│   ├── SETUP.md                         # Development setup guide
│   ├── API.md                           # Service layer API documentation
│   └── DECISIONS.md                     # Detailed design decision log
│
└── README.md
```

### Directory Annotations

- **App/:** Application entry point and navigation coordination
- **Models/:** Data models with business logic (but not service calls)
- **Services/:** Business logic layer - CRUD, validation, notifications
- **ViewModels/:** State management for UI, orchestrates Services and data queries
- **Views/:** SwiftUI components organized by feature area
- **Components/:** Reusable UI elements used across features
- **Utilities/:** Helper functions, extensions, constants
- **Resources/:** Localizable strings, assets, configuration

---

## 4. Data Layer

### SwiftData Task Model

```swift
import SwiftData
import Foundation

@Model
final class Task {
    /// Unique identifier for the task
    // No @Attribute(.unique) — CloudKit sync requires no unique constraints
    var id: UUID

    /// Task title/name (required)
    var title: String

    /// Extended notes and details (optional)
    var notes: String?

    /// Region: morning, afternoon, evening, or backlog
    var region: Region

    /// Priority bucket: must (1), complementary (3), misc (5), none (unassigned)
    var bucket: TaskBucket

    /// Current status: todo, doing, done
    var status: TaskStatus

    /// Date task is planned for (defaults to current date)
    var plannedDate: Date

    /// When task was created
    var createdAt: Date

    /// Last modification timestamp
    var updatedAt: Date

    /// Display order within region+bucket (lower = higher priority visually)
    var order: Int

    /// If true, task automatically carries over to next day if not completed
    var autoCarry: Bool

    /// If true, task stays at top of region
    var isSticky: Bool

    /// Optional expiration date (task auto-archives after)
    var expiresAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        region: Region = .backlog,
        bucket: TaskBucket = .none,
        status: TaskStatus = .todo,
        plannedDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        order: Int = 0,
        autoCarry: Bool = false,
        isSticky: Bool = false,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.region = region
        self.bucket = bucket
        self.status = status
        self.plannedDate = plannedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.order = order
        self.autoCarry = autoCarry
        self.isSticky = isSticky
        self.expiresAt = expiresAt
    }

    /// Computed property: is this task overdue?
    var isOverdue: Bool {
        guard status != .done else { return false }
        return plannedDate < Date().startOfDay
    }

    /// Computed property: is this task expired?
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }
}

// MARK: - Enums

enum Region: String, Codable, CaseIterable, Comparable {
    case morning
    case afternoon
    case evening
    case backlog

    var displayName: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .backlog: "Backlog"
        }
    }

    var order: Int {
        switch self {
        case .morning: 0
        case .afternoon: 1
        case .evening: 2
        case .backlog: 3
        }
    }

    static func < (lhs: Region, rhs: Region) -> Bool {
        lhs.order < rhs.order
    }
}

enum TaskBucket: String, Codable, CaseIterable, Comparable {
    case must       // Priority 1 - must accomplish
    case complementary // Priority 3 - nice to have
    case misc       // Priority 5 - would be nice
    case none       // Not assigned to bucket

    var displayName: String {
        switch self {
        case .must: "Must (1)"
        case .complementary: "Complementary (3)"
        case .misc: "Misc (5)"
        case .none: "Unassigned"
        }
    }

    var maxCount: Int {
        switch self {
        case .must: 1
        case .complementary: 3
        case .misc: 5
        case .none: Int.max
        }
    }

    var order: Int {
        switch self {
        case .must: 0
        case .complementary: 1
        case .misc: 2
        case .none: 3
        }
    }

    static func < (lhs: TaskBucket, rhs: TaskBucket) -> Bool {
        lhs.order < rhs.order
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo       // Not started
    case doing      // In progress
    case done       // Completed

    var displayName: String {
        switch self {
        case .todo: "To Do"
        case .doing: "Doing"
        case .done: "Done"
        }
    }
}
```

### Key Data Design Decisions

1. **UUID for id:** Enables offline-first support and future cloud sync without server-generated IDs
2. **plannedDate:** Allows scheduling tasks for future days; paired with DayRolloverService
3. **bucket:** Enforces 1-3-5 rule at data level; validated by TaskService
4. **autoCarry & isSticky:** Provides flexible task management without complex dependencies
5. **Timestamps (createdAt, updatedAt):** Enable future audit trails and conflict resolution

---

## 5. State Management

### ViewModel Pattern with @Observable and @Published

All ViewModels conform to the new Swift 6.0 @Observable pattern for reactive state management:

```swift
import Observation

@Observable
final class TaskListViewModel: Sendable {
    // MARK: - State
    var tasks: [Task] = []
    var selectedRegion: Region = .morning
    var isLoading: Bool = false
    var error: AppError? = nil

    // MARK: - Dependencies
    private let taskService: TaskService
    private let dayRolloverService: DayRolloverService

    init(
        taskService: TaskService,
        dayRolloverService: DayRolloverService
    ) {
        self.taskService = taskService
        self.dayRolloverService = dayRolloverService
    }

    // MARK: - Public Methods
    @MainActor
    func loadTodaysTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let today = Date().startOfDay
            tasks = try await taskService.fetchTasks(for: today)
        } catch {
            self.error = AppError.loadFailed(error.localizedDescription)
        }
    }

    @MainActor
    func createTask(_ task: Task, in region: Region) async {
        do {
            var newTask = task
            newTask.region = region
            newTask.plannedDate = Date().startOfDay
            try await taskService.createTask(newTask)
            await loadTodaysTasks()
        } catch {
            self.error = AppError.createFailed(error.localizedDescription)
        }
    }

    // More methods...
}
```

### Key State Management Principles

1. **@Observable:** Native Swift 6.0 observable macro; no third-party dependencies
2. **@MainActor:** Ensures all state mutations happen on main thread (SwiftUI requirement)
3. **async/await:** Modern concurrency model, no callbacks or DispatchQueue
4. **Sendable:** Compile-time verification of thread-safe data flow
5. **Error Handling:** Centralized error state on ViewModel for display in UI

### ViewModel Layer Responsibilities

- **Hold View State:** isLoading, error, selectedItem, filters, etc.
- **Fetch Data:** Call services, handle async operations
- **Business Logic:** Filtering, sorting, validation
- **Handle User Actions:** Create, update, delete task commands
- **Drive UI Updates:** State changes trigger SwiftUI view redraws

---

## 6. Service Layer

### TaskService

Handles all Task-related CRUD operations and business rule enforcement:

```swift
actor TaskService {
    private let container: ModelContext

    init(container: ModelContext) {
        self.container = container
    }

    // MARK: - CRUD Operations

    nonisolated func createTask(_ task: Task) throws {
        let context = container

        // Validate bucket count before insertion
        try validateBucketLimit(
            region: task.region,
            bucket: task.bucket,
            context: context
        )

        context.insert(task)
        try context.save()
    }

    nonisolated func updateTask(_ task: Task) throws {
        let context = container
        context.insert(task)
        try context.save()
    }

    nonisolated func deleteTask(_ taskID: UUID) throws {
        let context = container
        // Soft delete or hard delete based on requirements
        if let task = try context.fetch(FetchDescriptor<Task>()).first(where: { $0.id == taskID }) {
            context.delete(task)
            try context.save()
        }
    }

    nonisolated func fetchTasks(
        for date: Date,
        in region: Region? = nil
    ) throws -> [Task] {
        var descriptor = FetchDescriptor<Task>()
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay

        descriptor.predicate = #Predicate<Task> { task in
            task.plannedDate >= startOfDay && task.plannedDate <= endOfDay
        }

        if let region = region {
            descriptor.predicate = #Predicate<Task> { task in
                task.plannedDate >= startOfDay &&
                task.plannedDate <= endOfDay &&
                task.region == region
            }
        }

        descriptor.sortBy = [
            SortDescriptor(\.isSticky, order: .reverse),
            SortDescriptor(\.bucket),
            SortDescriptor(\.order)
        ]

        return try container.fetch(descriptor)
    }

    // MARK: - Business Logic

    nonisolated func validateBucketLimit(
        region: Region,
        bucket: TaskBucket,
        context: ModelContext
    ) throws {
        guard bucket != .none else { return }

        let count = try context.fetch(FetchDescriptor<Task>())
            .filter { $0.region == region && $0.bucket == bucket && $0.status != .done }
            .count

        if count >= bucket.maxCount {
            throw TaskServiceError.bucketFull(bucket)
        }
    }

    nonisolated func moveTask(
        _ taskID: UUID,
        to region: Region
    ) throws {
        guard let task = try fetchTask(taskID) else {
            throw TaskServiceError.notFound
        }
        task.region = region
        try updateTask(task)
    }
}

enum TaskServiceError: LocalizedError {
    case bucketFull(TaskBucket)
    case notFound
    case invalidOperation(String)

    var errorDescription: String? {
        switch self {
        case .bucketFull(let bucket):
            return "Cannot add more tasks to \(bucket.displayName)"
        case .notFound:
            return "Task not found"
        case .invalidOperation(let message):
            return message
        }
    }
}
```

### DayRolloverService

Manages automatic daily reset and task carryover:

```swift
actor DayRolloverService {
    private let taskService: TaskService
    private let container: ModelContext

    nonisolated func performDayRollover() async throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.startOfDay
        let yesterdaysTasks = try taskService.fetchTasks(for: yesterday)

        let incompleteTasks = yesterdaysTasks.filter {
            $0.status != .done && $0.autoCarry
        }

        for task in incompleteTasks {
            var carriedTask = task
            carriedTask.plannedDate = Date().startOfDay
            try taskService.createTask(carriedTask)
        }
    }
}
```

### NotificationService

Handles local notifications (no remote/push notifications in MVP):

```swift
actor NotificationService {
    nonisolated func scheduleNotification(
        for task: Task,
        at time: Date
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.notes ?? "Complete this task"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    nonisolated func cancelNotification(for taskID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }
}
```

---

## 7. Navigation

### Coordinator Pattern (Lightweight)

Charstack uses a lightweight Coordinator pattern for navigation without full-featured routing libraries:

```swift
@Observable
final class AppCoordinator: Sendable {
    enum Route: Hashable {
        case taskList
        case taskDetail(taskID: UUID)
        case createTask
        case editTask(taskID: UUID)
        case settings
    }

    var navigationPath: NavigationPath = NavigationPath()

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func pop() {
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}
```

### NavigationStack Usage

```swift
struct RootView: View {
    @State var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            TaskListView()
                .navigationDestination(for: AppCoordinator.Route.self) { route in
                    switch route {
                    case .taskList:
                        TaskListView()
                    case .taskDetail(let id):
                        TaskDetailView(taskID: id)
                    case .createTask:
                        TaskFormView(mode: .create)
                    case .editTask(let id):
                        TaskFormView(mode: .edit(id))
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environment(coordinator)
    }
}
```

### Navigation Design Decisions

1. **NavigationStack over NavigationView:** Modern SwiftUI 4.0+ API, easier to manage state
2. **Route enum:** Centralized, type-safe navigation definitions
3. **Lightweight Coordinator:** Avoids complex routing libraries; adds minimal overhead
4. **Deep Linking Ready:** Route enum enables future universal link support

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
- Requires iOS 17+ (acceptable for new app)
- Smaller ecosystem than CoreData
- Mitigation: Fallback to JSON export for compatibility

**Related:** Considered using Realm, but SwiftData's native status and iOS 17+ support won out

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

**Included Instead:**
- isSticky: Force task to top of region
- autoCarry: Automatic carryover to next day
- These features provide flexible task management without dependency graph complexity

**Future Enhancement:** Add optional "blockedBy" field and task graph traversal in v2 if user research validates need

---

### Decision 5: SwiftUI-Only (No UIKit)

**Decision:** 100% SwiftUI; no UIKit fallback components

**Rationale:**
- iOS 17+ baseline allows full SwiftUI feature set
- SwiftUI's declarative model maps perfectly to MVVM
- Faster iteration and preview-driven development
- Smaller codebase (no dual implementations)
- Better performance for list-heavy UIs

**Trade-offs:**
- Cannot target iOS 16 or earlier
- Some custom components may require workarounds (acceptable)
- Dependency on Apple's continued SwiftUI investment (justified)

**Implementation:** SwiftUI 4.0+ (available on iOS 17+); use modifiers over legacy apis

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
