import Observation
import SwiftUI

/// Lightweight coordinator managing app-level navigation via NavigationStack.
///
/// Routes are type-safe enum cases that map to destination views.
/// The coordinator is injected into the environment so any child view
/// can trigger navigation without coupling to NavigationLink directly.
@Observable
@MainActor
final class AppCoordinator {

    /// All navigable destinations in the app.
    enum Route: Hashable {
        /// The region focus view showing all tasks in a single region.
        case regionFocus(Region)
    }

    /// The navigation path backing the NavigationStack.
    var navigationPath = NavigationPath()

    /// Pushes a new route onto the navigation stack.
    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    /// Pops the top route from the navigation stack.
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    /// Pops all routes, returning to the root view.
    func popToRoot() {
        navigationPath = NavigationPath()
    }
}
