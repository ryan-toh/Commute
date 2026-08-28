import Observation

@MainActor
@Observable
final class NavigationRouteViewModel {
    private(set) var route: Route?
    private(set) var isPlanningRoute = false
    private(set) var routeError: Error?

    private let routePlanningService: any RoutePlanningService

    init(routePlanningService: any RoutePlanningService) {
        self.routePlanningService = routePlanningService
    }

    var nextStep: RouteStep? {
        route?.steps.first
    }

    func planRoute(to destination: Location, from origin: Location) async {
        isPlanningRoute = true
        routeError = nil
        defer { isPlanningRoute = false }

        do {
            route = try await routePlanningService.planCyclingRoute(from: origin, to: destination)
        } catch {
            routeError = error
        }
    }

    func clearRoute() {
        route = nil
        routeError = nil
    }
}
