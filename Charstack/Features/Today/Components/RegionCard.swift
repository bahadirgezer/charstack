import SwiftData
import SwiftUI

/// A summary card for a single region displayed on the Today dashboard.
///
/// Shows the region icon, name, must-do task title (if any), bucket fill counts,
/// and overall completion progress. Tapping navigates to the RegionFocusView.
struct RegionCard: View {
    let region: Region
    let tasks: [CharstackTask]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                regionHeader
                mustDoSection
                if region.isConstrained {
                    bucketCounts
                }
                progressBar
            }
            .padding(Theme.Spacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to open \(region.displayName)")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    private var regionHeader: some View {
        HStack {
            Image(systemName: region.systemImageName)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.regionColor(for: region))

            Text(region.displayName)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            Text("\(completedCount)/\(totalCount)")
                .font(Theme.Typography.captionMonospaced)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var mustDoSection: some View {
        Group {
            if region.isConstrained {
                if let mustTask = mustDoTask {
                    HStack(spacing: Theme.Spacing.small) {
                        Image(systemName: mustTask.status == .done ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(
                                mustTask.status == .done
                                    ? Theme.Colors.success
                                    : Theme.Colors.bucketColor(for: .must)
                            )
                            .font(Theme.Typography.subheadline)

                        Text(mustTask.title)
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(
                                mustTask.status == .done
                                    ? Theme.Colors.textTertiary
                                    : Theme.Colors.textPrimary
                            )
                            .strikethrough(mustTask.status == .done)
                            .lineLimit(1)
                    }
                } else {
                    HStack(spacing: Theme.Spacing.small) {
                        Image(systemName: "plus.circle.dashed")
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .font(Theme.Typography.subheadline)

                        Text("No must-do set")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .italic()
                    }
                }
            } else {
                Text("\(totalCount) task\(totalCount == 1 ? "" : "s") in backlog")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    private var bucketCounts: some View {
        HStack(spacing: Theme.Spacing.standard) {
            bucketCountBadge(bucket: .complementary)
            bucketCountBadge(bucket: .misc)
        }
    }

    private func bucketCountBadge(bucket: TaskBucket) -> some View {
        let activeTasks = tasks.filter { $0.bucket == bucket && $0.status.countsTowardBucketLimit }
        let completedTasks = tasks.filter { $0.bucket == bucket && $0.status == .done }
        let totalInBucket = activeTasks.count + completedTasks.count

        return HStack(spacing: Theme.Spacing.extraSmall) {
            Circle()
                .fill(Theme.Colors.bucketColor(for: bucket))
                .frame(width: 6, height: 6)

            Text("\(totalInBucket)/\(bucket.maxCount)")
                .font(Theme.Typography.captionMonospaced)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(bucket.shortLabel)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .accessibilityLabel("\(bucket.displayName): \(totalInBucket) of \(bucket.maxCount)")
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.textTertiary.opacity(0.2))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(completionFraction >= 1.0 ? Theme.Colors.success : Theme.Colors.regionColor(for: region))
                    .frame(width: geometry.size.width * completionFraction, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: completionFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Computed Properties

    private var totalCount: Int {
        tasks.count
    }

    private var completedCount: Int {
        tasks.filter { $0.status == .done }.count
    }

    private var completionFraction: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }

    private var mustDoTask: CharstackTask? {
        tasks.first { $0.bucket == .must }
    }

    private var accessibilityDescription: String {
        var parts = ["\(region.displayName) region"]
        parts.append("\(completedCount) of \(totalCount) tasks completed")
        if let must = mustDoTask {
            parts.append("Must do: \(must.title)\(must.status == .done ? ", completed" : "")")
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Preview

#Preview("Morning Card (with tasks)") {
    let container = PreviewData.container
    RegionCard(
        region: .morning,
        tasks: PreviewData.sampleTasks.filter { $0.region == .morning },
        onTap: {}
    )
    .padding()
    .background(Theme.Colors.groupedBackground)
    .modelContainer(container)
}

#Preview("Empty Evening Card") {
    RegionCard(
        region: .evening,
        tasks: [],
        onTap: {}
    )
    .padding()
    .background(Theme.Colors.groupedBackground)
}
