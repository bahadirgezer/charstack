import SwiftData
import SwiftUI

/// The root view of the app, setting up NavigationStack with coordinator routing.
///
/// Owns the AppCoordinator and TaskService instances, injecting them into the
/// environment and child views respectively. Handles navigation destination
/// mapping for all routes.
struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @Environment(\.modelContext) private var modelContext

    private var taskService: TaskService {
        TaskService(modelContext: modelContext)
    }

    var body: some View {
        @Bindable var coordinator = coordinator

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
        .environment(coordinator)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
