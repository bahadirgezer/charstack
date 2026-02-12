import SwiftData
import SwiftUI

/// Detailed view for a single region showing all tasks grouped by bucket.
///
/// Displays tasks organized into Must-Do, Complementary, and Misc sections
/// with a QuickAddBar for inline task creation. Supports completion toggle,
/// swipe-to-delete, and context menu editing.
struct RegionFocusView: View {
    @State var viewModel: RegionFocusViewModel

    var body: some View {
        VStack(spacing: 0) {
            taskList
            if viewModel.region.isConstrained {
                QuickAddBar(region: viewModel.region) { title, bucket in
                    viewModel.addTask(title: title, bucket: bucket)
                }
            }
        }
        .background(Theme.Colors.groupedBackground)
        .navigationTitle(viewModel.region.displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                regionStatusBadge
            }
        }
        .task {
            viewModel.loadTasks()
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK") { viewModel.dismissError() }
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: $viewModel.isEditSheetPresented) {
            if let task = viewModel.taskBeingEdited {
                TaskEditSheet(
                    task: task,
                    onSave: { title, notes in
                        viewModel.updateTask(identifier: task.identifier, title: title, notes: notes)
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var taskList: some View {
        List {
            if viewModel.region.isConstrained {
                constrainedSections
            } else {
                backlogSection
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.tasks.isEmpty && !viewModel.isLoading {
                emptyStateView
            }
        }
    }

    @ViewBuilder
    private var constrainedSections: some View {
        ForEach(TaskBucket.constrainedBuckets) { bucket in
            Section {
                let bucketTasks = viewModel.tasks(for: bucket)
                if bucketTasks.isEmpty {
                    emptyBucketRow(bucket: bucket)
                } else {
                    ForEach(bucketTasks, id: \.identifier) { task in
                        taskRow(for: task)
                    }
                }
            } header: {
                bucketSectionHeader(bucket: bucket)
            }
        }
    }

    private var backlogSection: some View {
        Section {
            ForEach(viewModel.tasks, id: \.identifier) { task in
                taskRow(for: task)
                    .contextMenu {
                        moveToRegionMenu(for: task)
                    }
            }
        } header: {
            if !viewModel.tasks.isEmpty {
                Text("\(viewModel.tasks.count) task\(viewModel.tasks.count == 1 ? "" : "s")")
                    .font(Theme.Typography.caption)
            }
        }
    }

    private func taskRow(for task: CharstackTask) -> some View {
        TaskRow(
            task: task,
            onToggleCompletion: {
                viewModel.toggleTaskCompletion(identifier: task.identifier)
            },
            onDelete: {
                viewModel.deleteTask(identifier: task.identifier)
            },
            onEdit: {
                viewModel.beginEditing(task)
            }
        )
        .contextMenu {
            Button {
                viewModel.beginEditing(task)
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if viewModel.region != .backlog {
                moveToRegionMenu(for: task)
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteTask(identifier: task.identifier)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func moveToRegionMenu(for task: CharstackTask) -> some View {
        Menu {
            ForEach(Region.allCases.filter { $0 != viewModel.region }) { targetRegion in
                if targetRegion.isConstrained {
                    Menu(targetRegion.displayName) {
                        ForEach(TaskBucket.constrainedBuckets) { bucket in
                            Button {
                                viewModel.moveTask(
                                    identifier: task.identifier,
                                    toRegion: targetRegion,
                                    bucket: bucket
                                )
                            } label: {
                                Label(bucket.displayName, systemImage: "arrow.right")
                            }
                        }
                    }
                } else {
                    Button {
                        viewModel.moveTask(
                            identifier: task.identifier,
                            toRegion: targetRegion,
                            bucket: .unassigned
                        )
                    } label: {
                        Label(targetRegion.displayName, systemImage: targetRegion.systemImageName)
                    }
                }
            }
        } label: {
            Label("Move to...", systemImage: "arrow.right.circle")
        }
    }

    private func bucketSectionHeader(bucket: TaskBucket) -> some View {
        HStack {
            Circle()
                .fill(Theme.Colors.bucketColor(for: bucket))
                .frame(width: 8, height: 8)

            Text(bucket.displayName)
                .font(Theme.Typography.caption)

            Spacer()

            let remaining = viewModel.remainingCapacity(for: bucket)
            if remaining < bucket.maxCount {
                Text("\(bucket.maxCount - remaining)/\(bucket.maxCount)")
                    .font(Theme.Typography.captionMonospaced)
                    .foregroundStyle(
                        remaining == 0 ? Theme.Colors.warning : Theme.Colors.textTertiary
                    )
            }
        }
    }

    private func emptyBucketRow(bucket: TaskBucket) -> some View {
        HStack {
            Image(systemName: "plus.circle.dashed")
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(bucket == .must ? "Set your must-do" : "Add a task")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textTertiary)
                .italic()
        }
        .padding(.vertical, Theme.Spacing.extraSmall)
    }

    private var regionStatusBadge: some View {
        Text("\(viewModel.completedTaskCount)/\(viewModel.totalTaskCount)")
            .font(Theme.Typography.captionMonospaced)
            .foregroundStyle(Theme.Colors.textSecondary)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            systemImageName: viewModel.region.systemImageName,
            title: "No tasks in \(viewModel.region.displayName)",
            subtitle: "Use the bar below to add your first task",
            imageColor: Theme.Colors.regionColor(for: viewModel.region)
        )
    }
}

// MARK: - Preview

#Preview("Morning Region") {
    let container = PreviewData.container
    let taskService = TaskService(modelContext: container.mainContext)
    NavigationStack {
        RegionFocusView(viewModel: RegionFocusViewModel(region: .morning, taskService: taskService))
    }
    .modelContainer(container)
}

#Preview("Empty Region") {
    let container = PreviewData.container
    let taskService = TaskService(modelContext: container.mainContext)
    NavigationStack {
        RegionFocusView(viewModel: RegionFocusViewModel(region: .evening, taskService: taskService))
    }
    .modelContainer(container)
}
