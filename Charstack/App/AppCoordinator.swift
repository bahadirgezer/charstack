import Observation
import SwiftUI

/// Lightweight coordinator managing app-level navigation via NavigationStack and TabView.
///
/// Routes are type-safe enum cases that map to destination views.
/// The coordinator is injected into the environment so any child view
/// can trigger navigation without coupling to NavigationLink directly.
@Observable
@MainActor
final class AppCoordinator {

    /// The active tab in the root TabView.
    enum Tab: Hashable {
        case today
        case backlog
    }

    /// All navigable destinations within the Today tab's NavigationStack.
    enum Route: Hashable {
        /// The region focus view showing all tasks in a single region.
        case regionFocus(Region)
    }

    /// The currently selected tab.
    var selectedTab: Tab = .today

    /// The navigation path for the Today tab's NavigationStack.
    var navigationPath = NavigationPath()

    /// Pushes a new route onto the Today tab's navigation stack.
    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    /// Pops the top route from the navigation stack.
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    /// Pops all routes, returning to the root view of the current tab.
    func popToRoot() {
        navigationPath = NavigationPath()
    }

    /// Switches to the Backlog tab.
    func showBacklog() {
        selectedTab = .backlog
    }
}
