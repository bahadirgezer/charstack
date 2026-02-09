import SwiftData
import SwiftUI

/// Dedicated backlog view showing deferred and unscheduled tasks grouped by date.
///
/// Displays tasks in sections: "Today", "Yesterday", "This Week", "Older".
/// Each task supports move-to-region (with bucket selection), edit, and delete
/// via context menu and swipe actions.
struct BacklogView: View {
    @State var viewModel: BacklogViewModel

    var body: some View {
        List {
            if viewModel.groupedTasks.isEmpty && !viewModel.isLoading {
                Section {
                    EmptyStateView(
                        systemImageName: "tray",
                        title: "Backlog is empty",
                        subtitle: "Incomplete tasks will appear here after day rollover",
                        imageColor: Theme.Colors.regionColor(for: .backlog)
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.groupedTasks, id: \.group) { entry in
                    Section {
                        ForEach(entry.tasks, id: \.identifier) { task in
                            backlogTaskRow(for: task)
                        }
                    } header: {
                        groupSectionHeader(group: entry.group, count: entry.tasks.count)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Backlog")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.totalTaskCount > 0 {
                    Text("\(viewModel.totalTaskCount) task\(viewModel.totalTaskCount == 1 ? "" : "s")")
                        .font(Theme.Typography.captionMonospaced)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .task {
            viewModel.loadBacklogTasks()
        }
        .refreshable {
            viewModel.loadBacklogTasks()
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

    private func backlogTaskRow(for task: CharstackTask) -> some View {
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

            moveToRegionMenu(for: task)

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
            ForEach(Region.activeRegions, id: \.self) { targetRegion in
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
            }
        } label: {
            Label("Move to...", systemImage: "arrow.right.circle")
        }
    }

    private func groupSectionHeader(group: BacklogDateGroup, count: Int) -> some View {
        HStack {
            Image(systemName: group.systemImageName)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            Text(group.displayName)
                .font(Theme.Typography.caption)

            Spacer()

            Text("\(count)")
                .font(Theme.Typography.captionMonospaced)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview("With Tasks") {
    let container = PreviewData.container
    let taskService = TaskService(modelContext: container.mainContext)
    NavigationStack {
        BacklogView(viewModel: BacklogViewModel(taskService: taskService))
    }
    .modelContainer(container)
}

#Preview("Empty Backlog") {
    let container: ModelContainer = {
        do {
            return try ModelContainerSetup.createTestingContainer()
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }()
    let taskService = TaskService(modelContext: container.mainContext)
    NavigationStack {
        BacklogView(viewModel: BacklogViewModel(taskService: taskService))
    }
    .modelContainer(container)
}
