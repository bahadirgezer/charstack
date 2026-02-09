# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **UI Layer (Phase 1 Week 2)**
  - `TodayView` + `TodayViewModel` — main dashboard with four region cards, daily progress bar, rollover banner
  - `RegionCard` component — region summary with icon, must-do title, bucket fill counts, progress bar
  - `RegionFocusView` + `RegionFocusViewModel` — single-region task list grouped by bucket (Must/Comp/Misc)
  - `TaskRow` component — checkbox, title, notes preview, bucket badge, swipe actions (complete/delete), context menu
  - `QuickAddBar` component — inline task creation with title field, bucket picker, and add button
  - `TaskEditSheet` — modal sheet for editing task title and notes
  - `AppCoordinator` — lightweight NavigationStack coordinator with type-safe `Route` enum
  - `RootView` — root view wiring NavigationStack, coordinator, and destination mapping
  - `Theme` system — centralized colors (semantic + region/bucket), typography, spacing, and corner radius constants
  - `PreviewData` — in-memory container factory with sample tasks for SwiftUI previews
  - Navigation: Today → RegionFocus (tap region card), back navigation, context menu "Move to..." with sub-menus
  - Empty states for regions with no tasks and days with no planned tasks
  - Accessibility: labels, hints, combined elements, VoiceOver-friendly descriptions throughout
  - SwiftUI previews for all components (RegionCard, TaskRow, TodayView, RegionFocusView, QuickAddBar)

### Fixed
- `release.yml` — added missing `-destination` and code signing flags to archive step

- **Data Layer (Phase 1 Week 1)**
  - `CharstackTask` SwiftData model — CloudKit-safe (no unique constraints, all defaults)
  - `Region` enum (Morning, Afternoon, Evening, Backlog) with display names, SF Symbols, and sort ordering
  - `TaskBucket` enum (Must, Complementary, Misc, None) with 1-3-5 max counts
  - `TaskStatus` enum (Todo, InProgress, Done, Deferred) with lifecycle semantics
  - `ModelContainerSetup` — production (on-disk) and testing (in-memory) container factories
  - `TaskService` — full CRUD, 1-3-5 constraint enforcement, day rollover, capacity queries
  - `Date+Extensions` — startOfDay, endOfDay, isSameDay, addingDays, isBeforeToday
  - SwiftData wired into `CharstackApp.swift` entry point
- **Unit Tests (38 tests, all passing)**
  - `RegionTests` — all cases, display names, sort order, constraints
  - `TaskBucketTests` — max counts, 1-3-5 total, constrained buckets
  - `TaskStatusTests` — lifecycle flags, bucket limit semantics
  - `CharstackTaskTests` — initialization, accessors, completion, deferral, overdue logic
  - `TaskServiceTests` — CRUD, 1-3-5 enforcement per region/day, move, toggle, rollover, idempotency
  - `DateExtensionsTests` — all date helper methods
- Initial project structure with SwiftUI and MVVM architecture
- Documentation files:
  - Requirements specification
  - Architecture documentation
  - Project roadmap
- `.gitignore` configuration for Xcode projects
- `LICENSE` file (MIT License)
- `README.md` with project overview and setup instructions
- GitHub workflow templates for CI/CD and project management
- App Store compliance requirements (account deletion, Sign in with Apple, privacy policy)
- CloudKit-first cloud sync strategy documented in architecture
