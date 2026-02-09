# Shared/ — Context for Next Session

## What's Here

### Extensions/Date+Extensions.swift (Week 1)
Date helper methods: `startOfDay`, `endOfDay`, `isSameDay(_:)`, `addingDays(_:)`, `isBeforeToday`.

### Theme/Theme.swift (Week 2)
Lightweight theme system using nested enums:
- `Theme.Colors` — Semantic colors (background, text tiers), region-specific colors (`regionColor(for:)`), bucket-specific colors (`bucketColor(for:)`). Uses `Color(.systemBackground)` etc. for automatic dark mode.
- `Theme.Typography` — Font scale from `largeTitle` through `footnote`. Includes `captionMonospaced` for count displays like "2/3".
- `Theme.Spacing` — extraSmall(4), small(8), medium(12), standard(16), large(24), extraLarge(32).
- `Theme.CornerRadius` — small(6), medium(12), large(16).

### Preview/PreviewData.swift (Week 2)
`@MainActor enum PreviewData` with:
- `container` — Creates in-memory `ModelContainer` pre-populated with `sampleTasks`.
- `sampleTasks` — 13 tasks across all regions, buckets, and statuses. Includes completed and deferred tasks.
- `singleTask`, `completedTask` — Isolated tasks for component previews.

### Components/ (Week 3)
- **EmptyStateView.swift** — Reusable empty state component with configurable icon, title, subtitle, and icon color. Used by TodayView, RegionFocusView, and BacklogView.
- **TaskEditSheet.swift** — Shared edit sheet for task title/notes editing. Form with cancel/save toolbar buttons, `.presentationDetents([.medium])`. Used by RegionFocusView and BacklogView. (Extracted from RegionFocusView's private struct in Week 3.)

## Design Notes
- Theme is intentionally simple — static properties, no environment injection, no protocol-based theming.
- PreviewData creates a fresh container each access. This is fine for previews but don't use in production.
- Region colors: Morning=orange, Afternoon=yellow, Evening=indigo, Backlog=gray.
- Bucket colors: Must=red, Complementary=blue, Misc=gray, Unassigned=tertiaryLabel.
- Shared components take data + closures, never ViewModels. They're pure display components.
