# Charstack Requirements Document

## Document Information
- **Product**: Charstack iOS App (MVP)
- **Version**: 1.0
- **Last Updated**: February 8, 2026
- **Status**: Ready for Development
- **Target Platform**: iOS 26.0+
- **Architecture**: MVVM with SwiftUI + SwiftData

---

## 1. Executive Summary

**Charstack** is a minimal daily task manager designed to combat task list bloat by organizing work into four time-of-day regions—Morning, Afternoon, Evening, and Backlog—using a 1–3–5 constraint structure. The app emphasizes focus, intentionality, and consistent task completion.

### Core Value Proposition
- Replace infinite backlogs with time-of-day planning
- Enforce the 1–3–5 rule to prevent overcommitment
- Automatically manage task lifecycle (creation → completion → rollover)
- Maintain a minimal, calm, modern interface focused on execution

### Success Metric
**If Charstack consistently helps users complete their region Must-Dos, it's working.**

---

## 2. Functional Requirements

### 2.1 Core Task Management (FR-1.1.x)

#### FR-1.1.1: Create Task with Title and Optional Notes
- **Description**: User can create a new task with a title and optional notes.
- **Acceptance Criteria**:
  - Task creation requires a non-empty title
  - Notes field is optional (text)
  - Task appears in designated region immediately after creation
  - Task receives a unique ID and creation timestamp
- **Priority**: Must Have
- **Component**: RegionFocusView, QuickAddBar

#### FR-1.1.2: Assign Task to Region
- **Description**: User can assign a task to one of four regions: Morning, Afternoon, Evening, or Backlog.
- **Acceptance Criteria**:
  - Task displays in correct region view after assignment
  - Region assignment can be changed after creation
  - Tasks default to the current active region when created from that view
- **Priority**: Must Have
- **Component**: Task creation flow, TaskRow

#### FR-1.1.3: Assign Task Bucket Type
- **Description**: User can assign a task to a bucket type: Must-Do, Complementary, or Misc (Backlog items use "none").
- **Acceptance Criteria**:
  - Task displays with appropriate visual treatment based on bucket
  - Bucket type affects UI prominence (Must-Do > Complementary > Misc)
  - Bucket can be changed after creation
  - Tasks in Backlog region default to "none" bucket
- **Priority**: Must Have
- **Component**: TaskRow, RegionFocusView

#### FR-1.1.4: Enforce 1–3–5 Regional Constraints
- **Description**: Each active region (Morning, Afternoon, Evening) enforces a strict 1–3–5 task limit structure.
- **Acceptance Criteria**:
  - Maximum 1 Must-Do task per region
  - Maximum 3 Complementary tasks per region
  - Maximum 5 Misc tasks per region
  - Backlog has no default limit (configurable per settings in Phase 2)
  - UI prevents adding beyond limit or displays clear warning
  - Cannot convert a task to a bucket type if it would exceed the limit
  - Error message: "Morning region full (1 Must-Do, 3 Complementary, 5 Misc)"
- **Priority**: Must Have
- **Component**: TaskService, RegionFocusView

#### FR-1.1.5: Complete/Incomplete Task Status
- **Description**: User can toggle a task between complete and incomplete states.
- **Acceptance Criteria**:
  - Checkbox or swipe gesture marks task as done
  - Task visual state changes (strikethrough, reduced opacity)
  - Status persists immediately to SwiftData
  - Can mark incomplete again before day rollover
  - Completed tasks do NOT move to Backlog at day rollover (preserved in history)
- **Priority**: Must Have
- **Component**: TaskRow, TaskCheckbox

#### FR-1.1.6: Delete Task
- **Description**: User can permanently delete a task from the app.
- **Acceptance Criteria**:
  - Delete action available from task row (swipe or long-press menu)
  - Task removed from all views and database immediately
  - Optional: Undo within 5 seconds (Phase 2)
  - Confirmation dialog recommended but optional
- **Priority**: Must Have
- **Component**: TaskRow, RegionFocusView

#### FR-1.1.7: Edit Task Title and Notes
- **Description**: User can modify task title and notes after creation.
- **Acceptance Criteria**:
  - Edit view accessible from task detail or long-press
  - Changes persist immediately to SwiftData
  - Title validation (cannot be empty)
  - Notes can be cleared
- **Priority**: Must Have
- **Component**: Task detail/edit sheet

#### FR-1.1.8: Move Task Between Regions
- **Description**: User can move a task from one region to another.
- **Acceptance Criteria**:
  - Move action available via drag-and-drop or menu
  - Destination region respects 1–3–5 constraints
  - Task disappears from source, appears in destination
  - Bucket type may need adjustment if constraints require it
  - Error message if destination is full
- **Priority**: Must Have
- **Component**: RegionFocusView, TaskRow

#### FR-1.1.9: Reorder Tasks Within Bucket
- **Description**: User can manually reorder tasks within a bucket (Must-Do, Complementary, or Misc).
- **Acceptance Criteria**:
  - Drag-and-drop or long-press reorder gesture
  - Order persists across app restarts
  - Can only reorder within same bucket/region pair
  - Visual feedback during reorder (highlight, spacing)
- **Priority**: Should Have
- **Component**: TaskRow, RegionFocusView

---

### 2.2 Day Rollover (FR-1.2.x)

#### FR-1.2.1: Automatic Task Carry-Over to Backlog
- **Description**: At day transition (midnight or configured time), incomplete tasks automatically move from Morning/Afternoon/Evening to Backlog.
- **Acceptance Criteria**:
  - Rollover runs at day boundary (configurable in Phase 2, default: midnight)
  - Only incomplete tasks (status != done) move to Backlog
  - Region and bucket assignment are cleared (moved to Backlog "none" bucket)
  - Carries forward any task metadata (notes, created_date, carry_count)
  - Completed tasks remain in history
  - Rollover triggers on app launch if missed
- **Priority**: Must Have
- **Component**: DayRolloverService, AppDelegate/SceneDelegate

#### FR-1.2.2: Preserve Completed Tasks in History
- **Description**: Tasks marked as complete are preserved and do not roll over to Backlog.
- **Acceptance Criteria**:
  - Completed tasks remain in database with completion date/time
  - User can view completed tasks by date (optional for MVP)
  - Completed tasks do not clutter Backlog
  - Completion timestamp recorded
- **Priority**: Should Have
- **Component**: TaskService, History view (Phase 2)

#### FR-1.2.3: End-of-Day Review Notification
- **Description**: User receives an optional, configurable notification prompting end-of-day review.
- **Acceptance Criteria**:
  - Notification appears at configured time (default: 6 PM)
  - Tapping opens Backlog view or a review summary
  - Can be disabled in Settings
  - Gentle, non-intrusive language ("Time to review?")
- **Priority**: Should Have
- **Component**: NotificationService, SettingsView (Phase 2)

---

### 2.3 Backlog Management (FR-1.3.x)

#### FR-1.3.1: Display and Group Backlog Tasks
- **Description**: Backlog displays all unscheduled tasks grouped by age/source for quick scanning.
- **Acceptance Criteria**:
  - Tasks grouped by: "Today", "Yesterday", "This Week", "Older"
  - Each group shows task count
  - Can collapse/expand groups (optional)
  - Searching available (Phase 2)
  - Backlog view accessible from Today dashboard
- **Priority**: Must Have
- **Component**: BacklogView, BacklogViewModel

#### FR-1.3.2: Move Task from Backlog to Region
- **Description**: User can quickly move a task from Backlog into Morning/Afternoon/Evening.
- **Acceptance Criteria**:
  - Move action via long-press, menu, or gesture
  - Destination region must be specified
  - Bucket type (Must, Complementary, Misc) can be set or defaults
  - Respects 1–3–5 constraints
  - Task disappears from Backlog, appears in target region
  - Error message if destination is full
- **Priority**: Must Have
- **Component**: BacklogView, TaskRow

#### FR-1.3.3: Delete Task from Backlog
- **Description**: User can permanently remove a task from Backlog.
- **Acceptance Criteria**:
  - Delete action available from task row
  - Task removed from database immediately
  - Optional confirmation dialog
  - Removed task does not reappear in future rollovers
- **Priority**: Must Have
- **Component**: BacklogView, TaskRow

---

### 2.4 Today View / Dashboard (FR-1.4.x)

#### FR-1.4.1: Display Four Region Cards
- **Description**: Today view shows a card or section for each region: Morning, Afternoon, Evening, Backlog.
- **Acceptance Criteria**:
  - Each card displays:
    - Region name/icon
    - Must-Do task title (if exists) or placeholder
    - Count of Complementary tasks (e.g., "2/3")
    - Count of Misc tasks (e.g., "4/5")
    - Visual progress indicator (% complete or status)
  - Cards are visually distinct and easy to scan
  - Backlog card shows total unscheduled count
  - Empty state for regions with no tasks
- **Priority**: Must Have
- **Component**: TodayView, RegionCard

#### FR-1.4.2: Navigate to Region Focus View
- **Description**: Tapping a region card opens the detailed Region Focus view for that region.
- **Acceptance Criteria**:
  - Navigation is instant and smooth
  - Back button or swipe gesture returns to Today
  - Region context is clear in Region Focus header
- **Priority**: Must Have
- **Component**: TodayView, NavigationStack

#### FR-1.4.3: Show Overall Daily Progress
- **Description**: Today view displays an overall progress summary for the day.
- **Acceptance Criteria**:
  - Total tasks across all regions visible
  - Total completed tasks visible
  - Optional: % completion across day regions
- **Priority**: Should Have
- **Component**: TodayView

---

### 2.5 Region Focus View (FR-1.5.x)

#### FR-1.5.1: Display Tasks Grouped by Bucket
- **Description**: Region Focus view displays all tasks in a region, organized by bucket (Must-Do, Complementary, Misc).
- **Acceptance Criteria**:
  - Must-Do section at top, visually prominent
  - Complementary section below
  - Misc section at bottom
  - Empty state if no tasks in a bucket
  - Section headers clearly labeled
  - Can scroll if many tasks
- **Priority**: Must Have
- **Component**: RegionFocusView, TaskRow, SectionHeader

#### FR-1.5.2: Quick Add Task in Region
- **Description**: User can add a task directly from the Region Focus view without leaving context.
- **Acceptance Criteria**:
  - Quick add input bar at top or bottom of region view
  - User enters task title, task is created immediately
  - Bucket type can be selected (defaults to Misc if not specified)
  - New task appears in appropriate bucket section
  - Input clears after creation for rapid entry
- **Priority**: Must Have
- **Component**: QuickAddBar, RegionFocusView

#### FR-1.5.3: Complete Tasks via Checkbox or Swipe
- **Description**: User can mark tasks as complete with intuitive gestures.
- **Acceptance Criteria**:
  - Checkbox at left of task row toggles done state
  - Swipe-right gesture optional marks task done
  - Visual feedback (strikethrough, opacity change, brief animation)
  - Status persists immediately
  - Completed task remains in view (Phase 2: can auto-hide option)
- **Priority**: Must Have
- **Component**: TaskRow, TaskCheckbox

#### FR-1.5.4: Edit/Delete from Region View
- **Description**: User can edit or delete tasks directly from Region Focus view.
- **Acceptance Criteria**:
  - Long-press or menu icon shows actions (Edit, Move, Delete, Add Note)
  - Edit opens sheet with title/notes fields
  - Delete removes task permanently
  - Move allows reassigning to another region
- **Priority**: Must Have
- **Component**: TaskRow, ContextMenu

---

### 2.6 App Store Compliance (FR-1.6.x)

#### FR-1.6.1: Account Deletion (Guideline 5.1.1(v))
- **Description**: Provide in-app account deletion capability that fully removes user accounts and associated data.
- **App Store Requirement**: Mandatory since June 2022
- **Acceptance Criteria**:
  - Account deletion accessible in Settings > Account > Delete Account
  - Deletion must be full, not just deactivation
  - All associated user data deleted from system
  - If Sign in with Apple is used, tokens must be revoked via REST API
  - User informed about active subscriptions before deletion completes
  - Deletion confirmation dialog with clear language
- **Priority**: Must Have
- **Phase**: Phase 2+
- **Component**: SettingsView, AccountManager

#### FR-1.6.2: Sign in with Apple (Guideline 4.8)
- **Description**: If app offers any third-party login option (e.g., Google), must also offer Sign in with Apple.
- **App Store Requirement**: Mandatory
- **Acceptance Criteria**:
  - Sign in with Apple available if any other third-party authentication exists
  - Presented as equal or more prominent option than alternatives
  - Login flow is smooth and uses Apple's authentication framework
  - User identity properly managed via Apple's system
- **Priority**: Must Have
- **Phase**: Phase 3 (when BaaS integration added)
- **Component**: AuthenticationView, AccountManager

#### FR-1.6.3: Privacy Policy (Guideline 5.1.1)
- **Description**: Maintain accessible privacy policy both in-app and in App Store Connect.
- **App Store Requirement**: Mandatory
- **Acceptance Criteria**:
  - Privacy policy accessible in-app (Settings > Privacy Policy)
  - Privacy policy URL also in App Store Connect metadata
  - Policy discloses all data collected, usage, and third-party sharing
  - Includes SDK privacy manifests for all third-party dependencies
  - Updated when new SDKs or data collection methods added
- **Priority**: Must Have
- **Phase**: Phase 2+
- **Component**: SettingsView, Legal

#### FR-1.6.4: Demo Account for Review
- **Description**: Provide test credentials and documentation for App Store review process.
- **App Store Requirement**: Mandatory for apps with login
- **Acceptance Criteria**:
  - Working test account credentials provided in App Review Notes
  - Test account demonstrates all account-based features
  - Demo account remains active throughout review period
  - Clear instructions on how to access and use test account
- **Priority**: Must Have
- **Phase**: Phase 2+
- **Component**: Documentation, Test Infrastructure

#### FR-1.6.5: Minimal Data Collection (Guideline 5.1.1)
- **Description**: Collect only strictly necessary information during registration and onboarding.
- **App Store Requirement**: Mandatory
- **Acceptance Criteria**:
  - Registration form requests only essential fields
  - No phone number, date of birth, or personal data unless genuinely required
  - User can understand why each field is collected
  - Optional fields clearly marked as optional
- **Priority**: Must Have
- **Phase**: Phase 2+
- **Component**: RegistrationView, UserProfile

#### FR-1.6.6: Privacy Nutrition Labels
- **Description**: Accurately declare all data types collected in App Store Connect privacy manifest.
- **App Store Requirement**: Mandatory
- **Acceptance Criteria**:
  - All collected data types declared in App Store Connect
  - Privacy labels match actual data collection practices
  - Updated whenever new SDKs or data collection methods introduced
  - Compliance verified before each release
- **Priority**: Must Have
- **Phase**: Phase 2+
- **Component**: Compliance, Release Management

---

## 3. Non-Functional Requirements

### 3.1 Performance (NFR-2.1.x)

#### NFR-2.1.1: App Launch Time
- **Specification**: App launches in less than 2 seconds on iPhone 13 or newer.
- **Measurement**: Time from icon tap to first interactive screen (Today view).
- **Testing**: Measured on physical device, multiple runs averaged.

#### NFR-2.1.2: Scrolling Performance
- **Specification**: Task list scrolling maintains 60 FPS with 100+ tasks in a view.
- **Measurement**: Frame rate monitoring in Xcode Instruments.
- **Implementation**: Lazy loading, @Query optimization, onAppear/onDisappear cleanup.

#### NFR-2.1.3: Task Update Responsiveness
- **Specification**: Task creation, completion, or deletion reflects in UI within 100ms.
- **Measurement**: Time from user action (tap, swipe) to visual change.
- **Implementation**: Direct SwiftData writes, no network latency.

#### NFR-2.1.4: Memory Usage
- **Specification**: App memory footprint under 200 MB in normal use (< 5 tasks per region).
- **Measurement**: Xcode Memory Debugger, long-running session.
- **Implementation**: Proper cleanup of observers, no retain cycles.

---

### 3.2 Data Persistence (NFR-2.2.x)

#### NFR-2.2.1: Local Data Storage
- **Specification**: All task data persists locally on device using SwiftData.
- **Guarantee**: No cloud storage, no network dependency for core functionality.
- **Scope**: Tasks, regions, status, timestamps, order, notes.

#### NFR-2.2.2: Data Integrity and Loss Prevention
- **Specification**: No data loss on app termination, crash, or device reboot.
- **Guarantee**: All writes to SwiftData are synchronous; no data in flight.
- **Testing**: Force quit app, device restart, low-storage scenarios.

#### NFR-2.2.3: Migration Strategy
- **Specification**: Schema changes in future versions handled gracefully.
- **Plan**: SwiftData migration API for v1.1+ (add new properties, rename fields).
- **Approach**: Version model, provide migration closures in modelContainer setup.
- **Example**: If adding "priority" field to Task, provide default value in migration.

#### NFR-2.2.4: Backup and Recovery
- **Specification**: User can optionally back up and restore tasks (Phase 2).
- **Formats**: JSON export, Charstack file format, or iCloud backup.
- **Not MVP**: Local-only persistence sufficient for v1.0.

---

### 3.3 Accessibility (NFR-2.3.x)

#### NFR-2.3.1: Accessibility Labels and Hints
- **Specification**: All interactive elements have clear accessibility labels.
- **Examples**:
  - Button: "Mark task complete"
  - Checkbox: "Complete {task title}"
  - Region card: "Morning region, 1 Must-Do, 2 Complementary, 3 Misc, 50% complete"
  - Add button: "Add new task to Misc"
- **Testing**: Xcode Accessibility Inspector, VoiceOver on device.

#### NFR-2.3.2: Dynamic Type Support
- **Specification**: App supports all Dynamic Type sizes (xSmall to xxxLarge).
- **Measurement**: Test at minimum and maximum sizes.
- **Implementation**: Use SwiftUI's `.font(.body)`, `.font(.headline)` modifiers, avoid fixed CGFloat sizes.
- **Guarantee**: Text remains readable, layouts don't break.

#### NFR-2.3.3: VoiceOver Compatibility
- **Specification**: Core user workflows are fully navigable via VoiceOver.
- **Core Workflows**:
  1. Plan a task in Morning region
  2. Complete a task with checkbox
  3. Move incomplete task from Morning to Afternoon
  4. Pull a task from Backlog into today's plan
- **Testing**: Manual VoiceOver navigation on device.

#### NFR-2.3.4: Color Contrast
- **Specification**: All text meets WCAG AA standard (4.5:1 for body text, 3:1 for large text).
- **Testing**: WebAIM contrast checker or Xcode Accessibility tools.
- **Guarantee**: No reliance on color alone to convey information (use icons + text).

---

### 3.4 iOS Version Support (NFR-2.4.x)

#### NFR-2.4.1: Minimum iOS Version
- **Requirement**: iOS 26.0 minimum.
- **Rationale**: Enables SwiftData (no CoreData), latest SwiftUI features, Swift 6 support.
- **Testing**: Deploy to iOS 26.0 simulator and iPhone 17 Pro or newer device.

#### NFR-2.4.2: Device Support
- **Primary**: iPhone (all current and prior-generation models).
- **Not MVP**: iPad-specific layouts deferred to v1.4.
- **Orientation**: Portrait primary; landscape optional.

#### NFR-2.4.3: iOS Features Used
- **Required**: SwiftData, SwiftUI 5.0+, EventKit (Phase 2), UserNotifications (Phase 2).
- **Optional**: Haptic Feedback (Phase 3), WidgetKit (v1.1).

---

### 3.5 Localization (NFR-2.5.x)

#### NFR-2.5.1: Base Language and Future Localization
- **MVP**: English only (US/UK).
- **Future**: Prepare string resources in `Localizable.strings` for easy translation.
- **Post-MVP**: Spanish, French, German, Japanese (no timeline yet).

---

### 3.6 Security and Privacy (NFR-2.6.x)

#### NFR-2.6.1: Data Privacy
- **Guarantee**: No data transmitted off-device, no analytics, no crash reporting (MVP).
- **Permissions**: Only request necessary permissions (notifications, calendar).
- **User Control**: User can disable notifications or calendar integration anytime.

#### NFR-2.6.2: No Credentials Storage
- **Specification**: App requires no login, no stored passwords, no authentication.
- **Implication**: All data local to device, tied to device security.

---

## 4. Out of Scope (MVP)

### Phase 1 Exclusions
The following features are intentionally excluded from v0.1 MVP to maintain focus and meet deadlines:

#### Cloud Sync & Account
- [ ] CloudKit sync (Phase 2 - iCloud device sync)
- [ ] User accounts with Sign in with Apple (Phase 3 - BaaS integration)
- [ ] Google Sign-In (Phase 3)
- [ ] Account deletion flow (Phase 3 - App Store requirement)
- [ ] Cross-platform web interface (Future)

#### Advanced Task Features
- [ ] Recurring tasks
- [ ] Task dependencies
- [ ] Subtasks or nested tasks
- [ ] Tags/labels beyond regions
- [ ] Task priority field
- [ ] Estimated duration / time blocking
- [ ] Task templates

#### Calendar Integration
- [ ] Calendar event creation (write access)
- [ ] Time block scheduling
- [ ] Calendar sync with tasks
- [ ] Conflict detection (Event Kit read-only in Phase 2)

#### UI Customization
- [ ] Custom themes or color schemes
- [ ] Layout customization
- [ ] Font selection
- [ ] Icon packs

#### Notifications (Phase 3)
- [ ] Morning summary notification
- [ ] End-of-day review notification
- [ ] Region transition nudges
- [ ] Overdue task alerts

#### Widgets & Extensions (Post-MVP)
- [ ] Today widget
- [ ] Lock screen widget
- [ ] Watch app
- [ ] Siri shortcuts
- [ ] Keyboard shortcuts

#### Export & Sharing
- [ ] PDF export of tasks
- [ ] JSON/CSV export
- [ ] Sharing to other apps
- [ ] Print support

#### Analytics & Insights
- [ ] Completion statistics
- [ ] Streak tracking
- [ ] Weekly review summary
- [ ] Productivity graphs
- [ ] Anonymous usage data

#### Collaboration
- [ ] Shared tasks or Backlogs
- [ ] Team workspaces
- [ ] Comments or annotations
- [ ] Multi-user sync

#### Mobile Features (Future Versions)
- [ ] Offline-first sync
- [ ] Voice input ("Add task to Morning")
- [ ] Handwriting/drawing support
- [ ] Biometric authentication (not needed for MVP)

---

## 5. User Stories

### Story 1: Morning Planning
**Title**: Plan morning tasks to start the day with focus
**Actor**: Daily user who wants to organize their morning
**Motivation**: Begin the day with clear priorities and avoid decision fatigue

#### Scenario
1. **Given** user opens Charstack app (7:00 AM)
2. **When** user lands on Today view
3. **Then** Morning card is empty and ready for planning

4. **When** user taps "Morning" card
5. **Then** RegionFocusView opens showing Morning region (empty state)

6. **When** user taps quick add bar and types "Finish project proposal"
7. **Then** task is created with title entered

8. **When** user assigns bucket type as "Must-Do"
9. **Then** task appears under Must-Do section (1/1 filled)

10. **When** user adds "Reply to emails" as Complementary
11. **Then** task appears in Complementary section (1/3 filled)

12. **When** user adds "Water plants" as Misc
13. **Then** task appears in Misc section (1/5 filled)

14. **When** user returns to Today view (back gesture or button)
15. **Then** Morning card shows "Finish project proposal" with 1 Complementary, 1 Misc

#### Acceptance Criteria
- [ ] Quick add creates task in selected bucket
- [ ] Bucket assignment is reflected in UI immediately
- [ ] Region card shows accurate counts
- [ ] No validation errors or crashes

---

### Story 2: Focused Execution
**Title**: Complete high-priority work without distraction
**Actor**: User during work session
**Motivation**: Finish the Most Important Thing (Must-Do) before other tasks

#### Scenario
1. **Given** user has planned Morning with Must-Do "Finish project proposal"
2. **When** user opens Morning region in afternoon (1:00 PM)
3. **Then** Must-Do is displayed prominently at top of view

4. **When** user starts working and checks the checkbox next to Must-Do
5. **Then** task is marked complete (visual feedback: strikethrough, dimming)

6. **When** Must-Do is checked as done
7. **Then** Complementary tasks "unlock" or highlight (configurable: optional lock feature)

8. **When** user taps checkbox on "Reply to emails"
9. **Then** task is marked complete, count updates to 0/3

10. **When** user continues completing remaining tasks
11. **Then** Must-Do section remains prominent, progress updates in real-time

#### Acceptance Criteria
- [ ] Must-Do is visually dominant
- [ ] Checkbox toggle works reliably
- [ ] Completion state persists on app restart
- [ ] No lag between tap and visual update (< 100ms)

---

### Story 3: End of Day Cleanup
**Title**: Start fresh tomorrow with unfinished tasks in Backlog
**Actor**: User at end of workday
**Motivation**: Clear today's regions, preserve unfinished work, prepare for next day

#### Scenario
1. **Given** user has incomplete tasks in Morning ("Water plants") and Afternoon ("Finish report")
2. **When** midnight arrives (or configured rollover time)
3. **Then** app detects day boundary

4. **When** day rollover executes
5. **Then** incomplete tasks are moved to Backlog automatically

6. **When** user opens app next morning (or at night if checking)
7. **Then** Today view shows empty Morning/Afternoon/Evening regions (ready for new planning)

8. **When** user opens Backlog
9. **Then** Backlog shows "Water plants" and "Finish report" grouped under "Yesterday"

10. **When** user taps "Finish report" and selects "Move to Afternoon"
11. **Then** task moves back to Afternoon, can assign bucket type

#### Acceptance Criteria
- [ ] Rollover runs automatically at day boundary
- [ ] Incomplete tasks actually move to Backlog (not deleted)
- [ ] Completed tasks do NOT move to Backlog
- [ ] Regions are empty and ready for fresh planning
- [ ] Backlog shows accurate date grouping

---

### Story 4: Backlog Triage
**Title**: Manage accumulated tasks from previous days
**Actor**: User during planning or review session
**Motivation**: Prioritize and reschedule old work, stay on top of commitments

#### Scenario
1. **Given** user has accumulated 8 tasks in Backlog from past 3 days
2. **When** user opens Today view and taps Backlog card
3. **Then** BacklogView shows all 8 tasks grouped by date ("Today", "Yesterday", "This Week")

4. **When** user sees "Finish report" from Yesterday
5. **And** user long-presses task
6. **Then** context menu appears with options: Move to Region, Delete, Edit

7. **When** user selects "Move to Afternoon"
8. **Then** destination region selector appears (Morning, Afternoon, Evening)

9. **When** user selects "Afternoon"
10. **Then** bucket type selector appears (Must, Complementary, Misc)

11. **When** user selects "Complementary" (already has Must-Do in Afternoon)
12. **Then** task is added to Afternoon's Complementary section (if space available)

13. **When** Afternoon is now full (1 Must, 3 Complementary, 5 Misc)
14. **And** user tries to add another task to Afternoon
15. **Then** error message: "Afternoon region is full"

16. **When** user deletes old task "Expired project research"
17. **Then** task is permanently removed from Backlog

#### Acceptance Criteria
- [ ] Backlog displays all unscheduled tasks grouped by age
- [ ] Move action respects 1–3–5 constraints
- [ ] Error message shown if destination is full
- [ ] Delete removes task permanently
- [ ] Backlog count updates in Today view

---

## 6. Success Criteria for MVP Release

An MVP is considered complete when:

### Functional Completeness
- [ ] User can plan tasks across Morning, Afternoon, Evening using 1–3–5 structure
- [ ] All four regions are functional and enforce constraints
- [ ] User can add, edit, complete, delete, and reorder tasks
- [ ] User can move tasks between regions and buckets
- [ ] Tasks automatically roll over to Backlog at day boundary
- [ ] User can pull tasks from Backlog back into regions

### Quality & Stability
- [ ] No crashes during normal usage (create, complete, rollover, restart)
- [ ] Data persists across app restarts and force quit
- [ ] Performance meets targets (launch < 2s, scrolling 60 FPS)

### User Experience
- [ ] Interface is clean, minimal, and intuitive
- [ ] Navigation is smooth and context-aware
- [ ] Visual feedback is immediate and clear
- [ ] Empty states are friendly and informative

### Documentation
- [ ] Code comments on public APIs
- [ ] README with setup and feature overview
- [ ] ARCHITECTURE.md and REQUIREMENTS.md current

### Testing
- [ ] Manual testing on real device (iPhone 13+)
- [ ] All core workflows tested
- [ ] Day rollover tested by changing device time
- [ ] Basic accessibility review (VoiceOver, Dynamic Type)

---

## 7. Definitions

### Must-Do
A single critical task per region. Completion unlocks Complementary tasks (optional lock feature in settings).

### Complementary
Up to three supporting tasks that unlock after Must-Do completion (configurable). Medium priority.

### Misc
Up to five small, low-friction tasks. Can be completed in any order. Lowest priority.

### Backlog
Holding area for unfinished tasks from previous days and future ideas. No default 1–3–5 limit.

### Day Rollover
Automatic process at midnight (or configured time) that moves incomplete tasks from Morning/Afternoon/Evening to Backlog.

### Region
One of four time-of-day sections: Morning, Afternoon, Evening, Backlog.

### 1–3–5 Rule
Structure enforcing 1 Must-Do, up to 3 Complementary, up to 5 Misc per active region.

### Sticky Task
(Phase 2+) Task that stays in a region until explicitly marked done, even after day rollover.

### Auto-Carry
(Phase 2+) Task-level override to automatically roll forward to same region next day.

---

## 8. Constraints & Assumptions

### Technical Constraints
- iOS 26.0+ only (no iOS 16 support)
- iPhone primary; iPad deferred
- SwiftUI 100%; no UIKit
- SwiftData for persistence (no CoreData)
- No third-party dependencies for MVP

### Business Constraints
- Single-user app (no collaboration)
- No cloud sync in MVP
- No monetization in v1.0
- Open source (MIT license)

### Assumptions
- Users have consistent daily structure (morning, afternoon, evening)
- Users have device with reliable time/date (no manual sync)
- Users accept local-only data (no backup service)
- Users willing to receive optional notifications

---

## 9. Dependencies & Risks

### External Dependencies
- **EventKit** (Phase 2): Calendar access (iOS permission)
- **UserNotifications** (Phase 3): Notifications (iOS permission)
- **WidgetKit** (v1.1): Today widget

### Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| SwiftData schema issues | Medium | High | Plan migration strategy early, test on sample data |
| Day rollover logic bugs | Medium | High | Extensive unit tests, manual testing with time changes |
| UI performance with 100+ tasks | Low | Medium | Use @Query filtering, pagination in Backlog, Instruments profiling |
| User confusion with 1–3–5 | Medium | Low | Clear onboarding, in-app hints, helpful empty states |
| Notification permission denied | Low | Low | Graceful fallback, no required permissions |

---

## 10. Future Enhancements (Post-MVP)

### v1.1: Quick Wins (2–3 weeks post-launch)
- Today widget showing regions + progress
- Task search in Backlog
- Undo delete within 5 seconds
- Dark mode refinements
- Completion animations

### v1.2: Calendar & Execution
- Read-only EventKit integration (show calendar events)
- Free time detection per region
- Focus timer linked to Must-Do

### v1.3: Notifications & Insights
- Morning summary notification
- Evening review notification
- Weekly review summary
- Completion statistics

### v1.4: Platform Expansion
- iPad optimized layout
- Mac Catalyst version
- Apple Watch complications (minimal)

### Future (Unscheduled)
- CloudKit sync
- Collaboration/shared Backlog
- Recurring tasks
- Task dependencies
- Siri shortcuts
- AI-powered suggestions
- Export/import (JSON, CSV, PDF)

---

## 11. Sign-Off

| Role | Name | Date | Notes |
|------|------|------|-------|
| Product Owner | Bahadir | Feb 8, 2026 | Approved for MVP development |
| Tech Lead | Bahadir | Feb 8, 2026 | Architecture reviewed, risks assessed |
| Designer | — | — | Design phase to follow if needed |

---

## Appendix: References

- **Project Brief**: `/docs/PROJECT_BRIEF.md`
- **Architecture**: `/docs/ARCHITECTURE.md`
- **Roadmap**: `/docs/ROADMAP.md`
- **Development Checklist**: `.claude/today.md`

---

**Document Version**: 1.0
**Last Modified**: 2026-02-08
**Status**: Ready for Development Phase 1
