import SwiftUI

/// An inline task creation bar for rapid task entry within a region.
///
/// Provides a text field for the task title, a bucket picker, and an add button.
/// After creation, the input clears for rapid sequential entry.
struct QuickAddBar: View {
    let region: Region
    let onAddTask: (_ title: String, _ bucket: TaskBucket) -> Void

    @State private var taskTitle = ""
    @State private var selectedBucket: TaskBucket = .misc
    @FocusState private var isTitleFocused: Bool

    /// Buckets available for selection (excludes unassigned).
    private var selectableBuckets: [TaskBucket] {
        TaskBucket.constrainedBuckets
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                TextField("Add a task...", text: $taskTitle)
                    .font(Theme.Typography.body)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit { addTaskIfValid() }

                bucketPicker

                addButton
            }
        }
        .padding(.horizontal, Theme.Spacing.standard)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.secondaryGroupedBackground)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick add task to \(region.displayName)")
    }

    // MARK: - Subviews

    private var bucketPicker: some View {
        Menu {
            ForEach(selectableBuckets) { bucket in
                Button {
                    selectedBucket = bucket
                } label: {
                    Label(bucket.displayName, systemImage: selectedBucket == bucket ? "checkmark" : "")
                }
            }
        } label: {
            Text(selectedBucket.shortLabel)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.bucketColor(for: selectedBucket))
                .padding(.horizontal, Theme.Spacing.small)
                .padding(.vertical, Theme.Spacing.extraSmall)
                .background(
                    Theme.Colors.bucketColor(for: selectedBucket).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                )
        }
        .accessibilityLabel("Bucket: \(selectedBucket.displayName)")
        .accessibilityHint("Double tap to change bucket type")
    }

    private var addButton: some View {
        Button {
            addTaskIfValid()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Theme.Colors.textTertiary
                        : Theme.Colors.accent
                )
        }
        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityLabel("Add task")
    }

    // MARK: - Actions

    private func addTaskIfValid() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        onAddTask(trimmedTitle, selectedBucket)
        taskTitle = ""
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        QuickAddBar(region: .morning) { title, bucket in
            print("Add: \(title) (\(bucket.displayName))")
        }
    }
}
