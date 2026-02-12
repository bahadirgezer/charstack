import SwiftData
import SwiftUI

/// The root view of the app, setting up TabView with Today and Backlog tabs.
///
/// Owns the AppCoordinator and TaskService instances, injecting them into the
/// environment and child views respectively. Handles navigation destination
/// mapping for all routes and triggers day rollover on scene phase changes.
struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    /// Tracks the last date rollover was performed to avoid redundant calls within the same day.
    @State private var lastRolloverDate: Date?

    private var taskService: TaskService {
        TaskService(modelContext: modelContext)
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        TabView(selection: $coordinator.selectedTab) {
            Tab("Today", systemImage: "sun.max", value: AppCoordinator.Tab.today) {
                NavigationStack(path: $coordinator.navigationPath) {
                    TodayView(viewModel: TodayViewModel(taskService: taskService))
                        .navigationDestination(for: AppCoordinator.Route.self) { route in
                            switch route {
                            case .regionFocus(let region):
                                RegionFocusView(
                                    viewModel: RegionFocusViewModel(
                                        region: region,
                                        taskService: taskService
                                    )
                                )
                            }
                        }
                }
            }

            Tab("Backlog", systemImage: "tray", value: AppCoordinator.Tab.backlog) {
                NavigationStack {
                    BacklogView(viewModel: BacklogViewModel(taskService: taskService))
                }
            }
        }
        .environment(coordinator)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                performRolloverIfNeeded()
            }
        }
    }

    /// Triggers day rollover when the app becomes active, if it hasn't already run today.
    private func performRolloverIfNeeded() {
        let today = Date().startOfDay
        if lastRolloverDate == nil || lastRolloverDate != today {
            do {
                try taskService.performDayRollover()
                lastRolloverDate = today
            } catch {
                // Rollover errors are non-fatal; TodayView will also attempt rollover on load.
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
