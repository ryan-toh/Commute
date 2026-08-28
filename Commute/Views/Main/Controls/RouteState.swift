import Foundation

struct RouteState {
    let destination: Location?
    let sessionState: UserRouteState
    let nextStep: RouteStep?
    let progress: RouteProgress?
    let isPlanningRoute: Bool
    let routeError: Error?
    let navigationError: Error?
    let hasPlannedRoute: Bool
}

@MainActor
struct NavigationControls {
    let planRoute: (Location) -> Void
    let startNavigation: () -> Void
    let stopNavigation: () -> Void
}
