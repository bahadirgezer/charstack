import SwiftUI

/// A reusable empty state view with icon, title, and optional subtitle.
///
/// Used throughout the app when a list or section has no content to display.
/// Provides consistent styling and messaging for empty states.
struct EmptyStateView: View {
    let systemImageName: String
    let title: String
    var subtitle: String?
    var imageColor: Color = Theme.Colors.textTertiary

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: systemImageName)
                .font(.system(size: 40))
                .foregroundStyle(imageColor.opacity(0.4))

            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, Theme.Spacing.extraLarge)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview("With Subtitle") {
    EmptyStateView(
        systemImageName: "tray",
        title: "Backlog is empty",
        subtitle: "Tasks will appear here after day rollover"
    )
}

#Preview("Without Subtitle") {
    EmptyStateView(
        systemImageName: "sparkles",
        title: "All done for today!"
    )
}

#Preview("With Custom Color") {
    EmptyStateView(
        systemImageName: "sun.max",
        title: "No morning tasks",
        subtitle: "Tap below to add your first task",
        imageColor: Theme.Colors.regionColor(for: .morning)
    )
}
