import SwiftData
import SwiftUI

/// A single task row displaying checkbox, title, bucket indicator, and swipe actions.
///
/// Supports completion toggle via checkbox tap, and contextual swipe actions
/// for editing, deleting, and deferring tasks.
struct TaskRow: View {
    let task: CharstackTask
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            completionCheckbox
            taskContent
            Spacer()
            bucketIndicator
        }
        .padding(.vertical, Theme.Spacing.extraSmall)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onToggleCompletion()
            } label: {
                Label(
                    task.status == .done ? "Undo" : "Done",
                    systemImage: task.status == .done ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(Theme.Colors.success)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(task.status == .done ? .isSelected : [])
        .accessibilityHint("Double tap to toggle completion. Swipe for more actions.")
    }

    // MARK: - Subviews

    private var completionCheckbox: some View {
        Button {
            onToggleCompletion()
        } label: {
            Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(
                    task.status == .done
                        ? Theme.Colors.success
                        : Theme.Colors.textTertiary
                )
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.status == .done ? "Completed" : "Not completed")
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    task.status == .done
                        ? Theme.Colors.textTertiary
                        : Theme.Colors.textPrimary
                )
                .strikethrough(task.status == .done)
                .lineLimit(2)

            if let notes = task.notes, !notes.isEmpty {
                Text(notes)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var bucketIndicator: some View {
        Group {
            if task.bucket != .unassigned {
                Text(task.bucket.shortLabel)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.bucketColor(for: task.bucket))
                    .padding(.horizontal, Theme.Spacing.small)
                    .padding(.vertical, Theme.Spacing.extraSmall)
                    .background(
                        Theme.Colors.bucketColor(for: task.bucket).opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    )
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [task.title]
        if task.status == .done {
            parts.append("completed")
        }
        parts.append(task.bucket.displayName)
        if let notes = task.notes, !notes.isEmpty {
            parts.append("note: \(notes)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Active Task") {
    List {
        TaskRow(
            task: PreviewData.singleTask,
            onToggleCompletion: {},
            onDelete: {}
        )
    }
    .modelContainer(PreviewData.container)
}

#Preview("Completed Task") {
    List {
        TaskRow(
            task: PreviewData.completedTask,
            onToggleCompletion: {},
            onDelete: {}
        )
    }
    .modelContainer(PreviewData.container)
}
