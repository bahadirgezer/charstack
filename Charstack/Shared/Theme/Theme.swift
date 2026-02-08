import SwiftUI

/// Lightweight theme system providing consistent colors, typography, and spacing
/// across the app. Uses SwiftUI's built-in semantic colors where possible to
/// support dark mode automatically.
enum Theme {

    // MARK: - Colors

    enum Colors {
        /// Primary accent color used for interactive elements.
        static let accent = Color.accentColor

        /// Background color for the main content area.
        static let background = Color(.systemBackground)

        /// Grouped background (e.g., behind cards).
        static let groupedBackground = Color(.systemGroupedBackground)

        /// Secondary grouped background (e.g., card surface).
        static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)

        /// Primary text color.
        static let textPrimary = Color(.label)

        /// Secondary text color for subtitles and metadata.
        static let textSecondary = Color(.secondaryLabel)

        /// Tertiary text for placeholders and disabled states.
        static let textTertiary = Color(.tertiaryLabel)

        /// Success/completion color.
        static let success = Color.green

        /// Destructive/delete color.
        static let destructive = Color.red

        /// Warning color for constraints nearing capacity.
        static let warning = Color.orange

        /// Region-specific tint colors.
        static func regionColor(for region: Region) -> Color {
            switch region {
            case .morning: Color.orange
            case .afternoon: Color.yellow
            case .evening: Color.indigo
            case .backlog: Color.gray
            }
        }

        /// Bucket-specific indicator colors.
        static func bucketColor(for bucket: TaskBucket) -> Color {
            switch bucket {
            case .must: Color.red
            case .complementary: Color.blue
            case .misc: Color.gray
            case .unassigned: Color(.tertiaryLabel)
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        /// Large title for screen headers (e.g., "Today").
        static let largeTitle: Font = .largeTitle.weight(.bold)

        /// Title for section headers (e.g., "Morning").
        static let title: Font = .title2.weight(.semibold)

        /// Headline for card titles and prominent text.
        static let headline: Font = .headline

        /// Body text for task titles.
        static let body: Font = .body

        /// Subheadline for secondary information.
        static let subheadline: Font = .subheadline

        /// Caption for metadata and counts.
        static let caption: Font = .caption

        /// Caption with monospaced digits for counts (e.g., "2/3").
        static let captionMonospaced: Font = .caption.monospacedDigit()

        /// Footnote for timestamps and tertiary info.
        static let footnote: Font = .footnote
    }

    // MARK: - Spacing

    enum Spacing {
        /// Extra-small spacing (4pt).
        static let extraSmall: CGFloat = 4

        /// Small spacing (8pt).
        static let small: CGFloat = 8

        /// Medium spacing (12pt).
        static let medium: CGFloat = 12

        /// Standard spacing (16pt).
        static let standard: CGFloat = 16

        /// Large spacing (24pt).
        static let large: CGFloat = 24

        /// Extra-large spacing (32pt).
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        /// Small radius for badges and tags (6pt).
        static let small: CGFloat = 6

        /// Medium radius for cards (12pt).
        static let medium: CGFloat = 12

        /// Large radius for sheets and modals (16pt).
        static let large: CGFloat = 16
    }
}
