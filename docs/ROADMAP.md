# Charstack iOS Development Roadmap

A minimal daily task manager built with SwiftUI and SwiftData on iOS 26+.

---

## Timeline Overview

| Phase | Version | Duration | Status | Focus |
|-------|---------|----------|--------|-------|
| Phase 0 | N/A | Completed | ✅ Complete | Foundation & Planning |
| Phase 1 | v0.1.0 | 2-3 weeks | 🚧 In Progress | MVP Development |
| Phase 2 | v0.5.0 | 1 week | 📋 Pending | CloudKit Sync & Calendar |
| Phase 3 | v0.8.0 | 1 week | 📋 Pending | Notifications & Settings |
| Phase 4 | v1.0.0 | 1-2 weeks | 📋 Pending | Polish & App Store Launch |
| Phase 5 | v2.0.0 | 2-3 weeks | 📋 Planned | User Accounts & Cloud (BaaS) |
| Post-Launch | v2.1+ | Ongoing | 📋 Planned | Iterations & Expansion |

---

## Phase 0: Foundation ✅ COMPLETE

**Target Date:** February 8, 2026
**Branch:** main
**Git Tag:** `foundation/phase-0`

### Deliverables

- [x] Project Brief & Vision Document
- [x] Requirements Specification (functional & technical)
- [x] Architecture Design (MVVM with SwiftData)
- [x] Repository Structure & Project Organization
- [x] Git Workflow & Branch Strategy Documentation
- [x] Tech Stack Confirmation (iOS 26+, SwiftUI, SwiftData, MVVM)
- [x] Development Environment Setup Guide

**Completion Notes:**
- Foundation work complete as of February 8, 2026
- Ready to begin Phase 1 MVP Development

---

## Phase 1: MVP Development

**Version:** v0.1.0
**Duration:** 2-3 weeks
**Branch:** develop
**Git Tag:** `release/v0.1.0` (on merge to main)
**Target Completion:** Early March 2026

The MVP focuses on the core 1-3-5 daily task management experience with four regions and day rollover.

### Week 1: Data Layer & Core Models ✅ COMPLETE

**Objective:** Establish persistent data storage and business logic foundation

- [x] SwiftData Setup & Configuration
  - [x] App delegate/SwiftData container initialization
  - [x] Model container setup with migration strategy
  - [x] Error handling & data persistence validation

- [x] Task Model Definition
  - [x] CharstackTask @Model class with properties: identifier, title, notes, region, bucket, status, plannedDate, sortOrder, createdAt, updatedAt, completedAt
  - [x] Codable-ready raw value enums for future sync/export
  - [x] Sort descriptors for efficient queries

- [x] Enums & Constants
  - [x] Region enum (Morning, Afternoon, Evening, Backlog)
  - [x] TaskStatus enum (todo, inProgress, done, deferred)
  - [x] TaskBucket enum (must, complementary, misc, none)
  - [ ] Constants file for colors, spacing, animations (deferred to Week 2 — UI layer)

- [x] TaskService (Repository Pattern)
  - [x] CRUD operations (create, read, update, delete tasks)
  - [x] Query methods (fetch by date, region, status, backlog, single task by ID)
  - [x] 1-3-5 constraint validation (max 1, 3, 5 tasks per region)
  - [x] Day rollover batch operation (moves incomplete past tasks to backlog)

- [x] Unit Tests (38 tests, all passing)
  - [x] CharstackTask model tests (initialization, accessors, completion, deferral, overdue)
  - [x] Region, TaskBucket, TaskStatus enum tests
  - [x] TaskService constraint validation tests (per region, per day, completed exclusion)
  - [x] Date handling tests (startOfDay, endOfDay, isSameDay, addingDays)
  - [x] SwiftData integration tests (in-memory container, CRUD round-trips)

- [x] 1-3-5 Constraint Engine
  - [x] Validation logic preventing > 1 Must task per region
  - [x] Validation logic preventing > 3 Complementary tasks per region
  - [x] Validation logic preventing > 5 Misc tasks per region
  - [x] Backlog is unconstrained (no limit)
  - [x] Error feedback for constraint violations (TaskServiceError.bucketFull)

**Deliverables:**
- ✅ Stable SwiftData schema with no migration issues
- ✅ TaskService fully tested and documented
- ✅ Constraint engine preventing invalid states

---

### Week 2: UI — Today & Region Views ✅ COMPLETE

**Objective:** Build the main interface showing today's tasks by region

- [x] TodayView (Main Tab)
  - [x] Navigation structure setup (NavigationStack + AppCoordinator)
  - [x] Safe area handling for dynamic island
  - [x] Scroll view with four region cards
  - [x] Empty state for completed day
  - [x] Daily progress bar with completion count
  - [x] Rollover banner showing deferred task count

- [x] RegionCard Component
  - [x] Region name header with icon and visual hierarchy
  - [x] Task count badge (e.g., "2/3")
  - [x] Visual distinction between regions (per-region colors)
  - [x] Must-do task title display (or empty placeholder)
  - [x] Bucket fill counts (Complementary and Misc)
  - [x] Completion progress bar

- [x] RegionFocusView (Detail)
  - [x] Expanded view of a single region grouped by bucket sections
  - [x] Full task list for region (Must-Do, Complementary, Misc)
  - [x] Add task via QuickAddBar
  - [x] Edit (sheet), delete (swipe/context), move (context menu) actions
  - [x] Navigation back to today view
  - [x] Empty bucket placeholders
  - [x] Backlog view with ungrouped task list + move-to-region menu

- [x] TaskRow Component
  - [x] Checkbox for completion state with symbol transition
  - [x] Task title display with strikethrough on completion
  - [x] Bucket indicator badge (color-coded)
  - [x] Notes preview (1-line truncated)
  - [x] Swipe actions (complete, delete)
  - [x] Context menu (edit, move, delete)

- [x] Quick Add Form
  - [x] Title input field with keyboard submit
  - [x] Bucket type picker (menu-based)
  - [x] Add button with validation (disabled when empty)

- [x] ViewModels
  - [x] TodayViewModel (manages today's task state, loading, rollover, daily progress)
  - [x] RegionFocusViewModel (single region CRUD, bucket queries, edit sheet state)
  - [x] @Observable pattern with @MainActor (Swift 6.0)

- [x] UI Tests & Preview Integration
  - [x] SwiftUI previews for all components
  - [x] PreviewData helper with in-memory container and sample tasks
  - [x] Multiple preview variants (active/completed tasks, empty/full regions)

- [x] Theme System
  - [x] Centralized colors (semantic, region-specific, bucket-specific)
  - [x] Typography scale (largeTitle through footnote)
  - [x] Spacing and corner radius constants

**Deliverables:**
- ✅ Fully functional today view with all four region cards
- ✅ Add/edit/delete/complete/move task flow working end-to-end
- ✅ All UI components tested in previews
- ✅ Lightweight theme system for consistent styling

---

### Week 3: Backlog & Day Rollover ✅ COMPLETE

**Objective:** Complete core workflow with overflow handling and daily refresh

- [x] BacklogView (Tab)
  - [x] List of incomplete tasks from previous days
  - [x] Date grouping ("Today", "Yesterday", "This Week", "Older")
  - [x] Move-to-region action with bucket selection
  - [x] Edit, delete, completion toggle via context menu and swipe
  - [ ] Filter by date created (deferred to Phase 2)
  - [ ] Sort options (date, region, priority) (deferred to Phase 2)
  - [ ] Bulk actions (select multiple, move to today) (deferred to Phase 2)

- [x] Move Gesture/Action
  - [x] Context menu to move tasks to region with bucket selection
  - [x] Constraint validation before acceptance (1-3-5 enforcement)
  - [x] Error feedback if region is full (alert display)
  - [ ] Drag-and-drop gesture (deferred to Phase 4 polish)
  - [ ] Success animation/haptic feedback (deferred to Phase 4 polish)

- [x] Day Rollover (integrated into TaskService)
  - [x] Triggered on app launch via `.task` modifier
  - [x] Triggered on foreground return via `ScenePhase` observer in RootView
  - [x] Mark incomplete morning/afternoon/evening tasks as deferred
  - [x] Move deferred tasks to backlog automatically
  - [x] Preserve completed tasks in history
  - [x] Idempotent operation (safe to call multiple times)
  - [ ] User-configurable rollover time (deferred to Phase 3 Settings)

- [x] Empty States
  - [x] "No tasks for today" message with CTA (EmptyStateView)
  - [x] "Backlog is empty" message (EmptyStateView)
  - [x] Consistent empty state component (Shared/Components/EmptyStateView.swift)
  - [ ] "Day complete" celebration view (deferred to Phase 4 polish)

- [x] Persistence & App Lifecycle
  - [x] Handle app backgrounding/foregrounding (ScenePhase observer)
  - [x] Trigger day rollover check on app launch
  - [x] Track last rollover date to prevent redundant calls
  - [ ] Handle edge cases (time zone changes, device sleep) (deferred)

- [x] Navigation
  - [x] TabView with Today and Backlog tabs
  - [x] AppCoordinator updated with Tab enum and selectedTab state
  - [x] NavigationStack per tab for proper navigation hierarchy

- [x] Shared Components
  - [x] EmptyStateView extracted to Shared/Components/
  - [x] TaskEditSheet extracted from RegionFocusView to Shared/Components/

- [x] Unit Tests (86 tests, all passing — up from 38)
  - [x] BacklogDateGroupTests (7 tests) — date grouping, sorting, display names
  - [x] TaskServiceTests — 3 new grouped backlog tests

**Deliverables:**
- ✅ Complete daily workflow working end-to-end
- ✅ Backlog populated with yesterday's incomplete tasks via date-grouped sections
- ✅ Day rollover functioning reliably on launch and foreground return
- ✅ TabView navigation with Today and Backlog tabs

---

### MVP Definition of Done Checklist

Before tagging v0.1.0, all items must be complete:

- [ ] All Phase 1 weekly deliverables implemented
- [ ] Unit test coverage ≥ 80% for data layer
- [ ] UI responsive on iPhone 14, 15, 16 (plus SE)
- [ ] No console warnings or errors
- [ ] All memory leaks addressed (Xcode instruments verification)
- [ ] Accessibility pass (VoiceOver testing, Dynamic Type support)
- [ ] Dark mode fully functional
- [ ] Manual QA sign-off on:
  - [ ] Add task flow (all regions)
  - [ ] Edit/delete operations
  - [ ] 1-3-5 constraint enforcement
  - [ ] Day rollover accuracy
  - [ ] Backlog move functionality
  - [ ] App launch & background/foreground transitions
- [ ] Documentation updated (README, API docs for TaskService)
- [ ] Code reviewed and merged to develop branch

---

## Phase 2: CloudKit Sync & Calendar Integration

**Version:** v0.5.0
**Duration:** 1 week
**Branch:** develop
**Git Tag:** `release/v0.5.0`
**Target Completion:** Mid-March 2026

### Task Model Enhancements (Deferred from MVP)

The following properties were intentionally omitted from the Phase 1 `CharstackTask` model to keep the MVP simple. They are planned as additive schema changes in Phase 2:

- [ ] `autoCarry: Bool` — Task-level override to automatically roll forward to the same region next day instead of moving to Backlog
- [ ] `isSticky: Bool` — Force task to top of its region regardless of sort order
- [ ] `expiresAt: Date?` — Optional expiration date after which the task is auto-deleted from Backlog

Current MVP rollover moves ALL incomplete active-region tasks to Backlog unconditionally.

### CloudKit Setup

- [ ] Add iCloud capability to Xcode project
- [ ] Add Background Modes capability (Remote Notifications)
- [ ] Ensure all SwiftData model properties have defaults or are optional
- [ ] Remove any @Attribute(.unique) constraints (CloudKit incompatible)
- [ ] Test sync between two devices with same Apple ID
- [ ] Handle CloudKit sync errors gracefully
- [ ] Add sync status indicator in UI (optional)

### Calendar Integration

- [ ] Calendar View Tab
  - [ ] Month view with task count badges
  - [ ] Tap date to view tasks for that day
  - [ ] Visual indication of "completed days"
  - [ ] Navigation to past/future weeks

- [ ] Historical Task View
  - [ ] View all tasks (completed & incomplete) for selected date
  - [ ] Read-only for past dates
  - [ ] Completion time stamps
  - [ ] Statistics: tasks completed, streak, weekly summary

- [ ] CalendarViewModel
  - [ ] Fetch task counts for all dates
  - [ ] Handle date range queries efficiently
  - [ ] Compute completion metrics

- [ ] Testing
  - [ ] Calendar view loads correct task counts
  - [ ] Historical queries work across month boundaries
  - [ ] Performance acceptable for 6+ months of data

---

## Phase 3: Notifications & Settings

**Version:** v0.8.0
**Duration:** 1 week
**Branch:** develop
**Git Tag:** `release/v0.8.0`
**Target Completion:** Late March 2026

### Deliverables

- [ ] Settings View Tab
  - [ ] Notifications toggle
  - [ ] Daily reminder time picker
  - [ ] Regional reminder toggle (on/off per region)
  - [ ] Theme selection (light, dark, system)
  - [ ] Day rollover time configuration
  - [ ] About & version info

- [ ] Local Notifications
  - [ ] Daily reminder at configured time
  - [ ] Notification for overdue tasks (evening region)
  - [ ] Request user permission flow
  - [ ] Handle system notification settings

- [ ] SettingsViewModel
  - [ ] UserDefaults persistence for settings
  - [ ] Notification scheduling/cancellation
  - [ ] Observable settings updates

- [ ] Testing
  - [ ] Settings persist across app restarts
  - [ ] Notifications schedule and fire correctly
  - [ ] Permission flow works on first launch

---

## Phase 4: Polish & App Store Preparation

**Version:** v1.0.0
**Duration:** 1-2 weeks
**Branch:** develop → main
**Git Tag:** `release/v1.0.0`
**Target Completion:** Early-mid April 2026

### UI/UX Polish

- [ ] Animations & Transitions
  - [ ] Smooth region expand/collapse animations
  - [ ] Task completion checkmark animation
  - [ ] Page transitions between tabs
  - [ ] Loading state animations

- [ ] Visual Design
  - [ ] Consistent color palette (primary, secondary, accent)
  - [ ] Typography hierarchy reviewed
  - [ ] Spacing/padding audit
  - [ ] Icon consistency (SF Symbols)

- [ ] Interaction Design
  - [ ] Haptic feedback on task completion
  - [ ] Long-press context menus (iOS 15+ style)
  - [ ] Confirmation dialogs for destructive actions
  - [ ] Keyboard shortcuts on iPad

### Accessibility

- [ ] VoiceOver Testing
  - [ ] All interactive elements announced correctly
  - [ ] Logical navigation order
  - [ ] Gestures communicated clearly

- [ ] Dynamic Type Support
  - [ ] All text scales properly (7-point to extra large)
  - [ ] Layout adjustments for large text
  - [ ] No text truncation issues

- [ ] Color & Contrast
  - [ ] WCAG AA compliance for all text
  - [ ] No color-only information
  - [ ] High contrast mode support

### Comprehensive Testing

- [ ] Performance Testing
  - [ ] App launch time < 2 seconds
  - [ ] Smooth scrolling (60 FPS)
  - [ ] Memory usage < 100 MB baseline
  - [ ] Battery impact minimal

- [ ] Compatibility Testing
  - [ ] iOS 26.0 through latest version
  - [ ] All iPhone models (SE to Pro Max)
  - [ ] iPad support verified
  - [ ] iPadOS optimizations (split view, keyboard)

- [ ] Regression Testing
  - [ ] All Phase 1-3 features still functional
  - [ ] Edge cases (low storage, no network, etc.)
  - [ ] Extended use (24+ hours of continuous running)

### App Store Assets & Documentation

- [ ] App Metadata
  - [ ] App name, subtitle, description finalized
  - [ ] Keywords researched and optimized
  - [ ] Privacy policy drafted & linked
  - [ ] Support URL and contact email

- [ ] Screenshots & Preview Video
  - [ ] 5-7 screenshots for each device (iPhone 6.7", 6.1", 5.5")
  - [ ] Localized screenshots (English at minimum)
  - [ ] Optional: preview video (15-30 seconds)

- [ ] Build Artifacts
  - [ ] App icons (all required sizes, rounded corners)
  - [ ] Launch screen finalized
  - [ ] App thinning configured (bitcode, asset catalogs)

- [ ] Documentation
  - [ ] User guide / help documentation
  - [ ] Privacy policy
  - [ ] Terms of service (if applicable)
  - [ ] CHANGELOG for v1.0.0
  - [ ] Internal architecture documentation

### App Store Submission

- [ ] TestFlight Beta
  - [ ] Internal testing group (team members)
  - [ ] External testing group (5+ beta testers minimum)
  - [ ] Feedback collection & critical bug fixes
  - [ ] Beta duration: 1 week minimum

- [ ] Final Review
  - [ ] App review guidelines checklist
  - [ ] No rejected categories (gambling, alcohol, etc.)
  - [ ] Privacy policy page created and linked (GitHub Pages or similar)
  - [ ] App privacy nutrition labels filled in App Store Connect
  - [ ] Age rating questionnaire completed
  - [ ] Demo account credentials prepared (if login required at this version)
  - [ ] App review notes prepared

- [ ] Submission & Monitoring
  - [ ] Submit build to App Store Connect
  - [ ] Monitor review queue
  - [ ] Address any App Review rejections
  - [ ] Publish on approval

### Release Deliverables

- [ ] Git main branch with all Phase 1-4 code
- [ ] Version 1.0.0 tagged and released
- [ ] Signed .ipa build archived
- [ ] Release notes published (GitHub, website)
- [ ] Launch announcement ready

---

## Phase 5: User Accounts & Cloud (BaaS)

**Version:** v2.0.0
**Duration:** 2-3 weeks
**Branch:** develop
**Git Tag:** `release/v2.0.0`
**Target Completion:** TBD (post App Store launch)

### Authentication

- [ ] Integrate Backend-as-a-Service (Firebase or Supabase — TBD)
- [ ] Implement Sign in with Apple (App Store Guideline 4.8 — mandatory if any third-party login)
- [ ] Implement Google Sign-In
- [ ] Build login/signup flow UI
- [ ] Handle auth state persistence and token refresh
- [ ] Provide demo account for App Store review (Guideline requirement)

### Account Management (App Store Required)

- [ ] Account settings screen (profile, email, linked providers)
- [ ] Account deletion flow — Settings > Account > Delete Account (Guideline 5.1.1(v))
- [ ] Full data deletion on account delete (not just deactivation)
- [ ] Revoke Sign in with Apple tokens on deletion (REST API)
- [ ] Warn about active subscriptions before deletion
- [ ] Confirmation dialog with clear language
- [ ] Data deletion confirmation notification

### Cloud Data Sync

- [ ] Sync task data to BaaS cloud database
- [ ] Conflict resolution strategy (last-write-wins or merge)
- [ ] Offline-first with background sync
- [ ] Sync status indicator in UI
- [ ] Migration path from CloudKit-only to BaaS

### Privacy & Compliance (App Store Required)

- [ ] Privacy policy — accessible in-app AND App Store Connect
- [ ] Privacy nutrition labels — accurate data type declarations
- [ ] SDK privacy manifests for all third-party SDKs
- [ ] Minimal data collection during registration (Guideline 5.1.1)
- [ ] GDPR compliance considerations

### Definition of Done

- [ ] User can sign in with Apple or Google
- [ ] User can delete their account and all data from within the app
- [ ] Data syncs across devices via BaaS
- [ ] Privacy policy accessible in Settings and App Store
- [ ] Demo account works for App Store reviewers
- [ ] All App Store Review Guidelines satisfied

**Tag:** `v2.0.0-accounts`

---

## Post-Launch Improvements

### v1.1: Quick Wins

**Duration:** 1-2 weeks
**Focus:** User feedback & polish based on early app store reviews

- [ ] Smart Task Suggestions
  - [ ] Recurring task templates
  - [ ] Suggested tasks based on history
  - [ ] Quick templates (e.g., "Exercise", "Review", "Plan")

- [ ] Export & Sharing
  - [ ] Export daily/weekly summary as PDF
  - [ ] Share completion stats
  - [ ] CSV export for analysis

- [ ] Minor UX Improvements
  - [ ] Keyboard shortcuts reference (? key)
  - [ ] Swipe gesture tutorials (onboarding)
  - [ ] Task search across all regions/backlog

---

### v1.2: Power User Features

**Duration:** 2-3 weeks
**Focus:** Advanced task management for committed users

- [ ] Task Subtasks/Checklists
  - [ ] Add subtasks within a task
  - [ ] Partial completion tracking
  - [ ] Subtask progress indicator

- [ ] Task Tags & Filtering
  - [ ] Add tags to tasks (e.g., "work", "health", "personal")
  - [ ] Filter tasks by tag in calendar view
  - [ ] Tag management & cleanup

- [ ] Repeat/Recurring Tasks
  - [ ] Create recurring tasks (daily, weekly, monthly)
  - [ ] Smart snooze (defer by hours/days)
  - [ ] Recurring task templates

- [ ] Custom Regional Labels
  - [ ] Rename regions (e.g., "Urgent", "Important", "Nice-to-have")
  - [ ] Reorder regions
  - [ ] Custom colors per region

---

### v1.3: Insights & Analytics

**Duration:** 2-3 weeks
**Focus:** Data visualization and personal productivity metrics

- [ ] Completion Dashboard
  - [ ] Weekly completion rate (%)
  - [ ] Monthly trends graph
  - [ ] Best day/time for task completion
  - [ ] Region-specific completion rates

- [ ] Streak Tracking
  - [ ] Current daily completion streak
  - [ ] Longest streak ever
  - [ ] Streak preservation logic
  - [ ] Streak notifications/badges

- [ ] Personal Reports
  - [ ] Weekly summary email (opt-in)
  - [ ] Monthly recap with insights
  - [ ] Comparison to personal averages

- [ ] Data Export for Analysis
  - [ ] JSON export of all tasks & metadata
  - [ ] Integration with personal data tools

---

### v1.4: Platform Expansion

**Duration:** 3-4 weeks
**Focus:** Multi-platform and ecosystem integration

- [ ] iPadOS App
  - [ ] Optimized iPad layout (split view, multi-window)
  - [ ] Keyboard shortcuts (full list)
  - [ ] Trackpad/mouse support

- [ ] macOS Companion App
  - [ ] Mac version of Charstack
  - [ ] CloudKit sync between devices
  - [ ] Menu bar widget

- [ ] iCloud Sync (Optional)
  - [ ] Multi-device sync via CloudKit
  - [ ] Automatic backup
  - [ ] Conflict resolution

- [ ] Siri Shortcuts Integration
  - [ ] Shortcuts for common actions (add task, check today's tasks)
  - [ ] Voice command support
  - [ ] Automation triggers

- [ ] Home Screen Widgets
  - [ ] Small widget: today's task count
  - [ ] Medium widget: region summary
  - [ ] Large widget: all regions at a glance
  - [ ] Interactive widgets (check off tasks)

---

## Release Checklist Template

Use this checklist for each major release:

### Pre-Release (1 week before)

- [ ] Feature freeze: no new features, only bug fixes
- [ ] Automated test suite passes 100%
- [ ] Code review complete for all changes
- [ ] Dependency updates finalized
- [ ] Xcode linting passes (SwiftLint configured)
- [ ] Memory leak detection run (Instruments)

### Release Candidate

- [ ] Create release branch from develop
- [ ] Update version number (Info.plist, Xcode build settings)
- [ ] Update CHANGELOG with all changes
- [ ] Build archive and verify signing
- [ ] TestFlight build uploaded & distributed

### TestFlight Phase (3-5 days)

- [ ] Internal testers report no critical issues
- [ ] External testers feedback reviewed
- [ ] Performance benchmarks acceptable
- [ ] Accessibility audit completed
- [ ] Critical bugs fixed and rebuilt

### Final Submission

- [ ] Final build tested on device
- [ ] All assets in place (icons, screenshots, previews)
- [ ] App Store metadata complete and reviewed
- [ ] Submit build to App Store Connect
- [ ] Monitor App Review for rejection

### Post-Launch

- [ ] Monitor App Store reviews (daily for first week)
- [ ] Check crash logs via Xcode Organizer
- [ ] Respond to user feedback
- [ ] Plan hotfix if critical issues arise
- [ ] Announce release on social/website

---

## Notes & Conventions

- **Branches:** Main features on `develop`, hotfixes on `main`
- **Commits:** Atomic, descriptive, reference issues (e.g., "feat: add task filtering #12")
- **Git Tags:** Format `release/vX.Y.Z` for all releases
- **Testing:** Aim for ≥80% code coverage; prioritize data layer
- **Documentation:** Maintain README, API docs, and architecture diagrams
- **Review:** All merges to develop and main require code review

---

**Last Updated:** February 9, 2026 (Week 3 complete)
**Maintained By:** Bahadır Gezer
