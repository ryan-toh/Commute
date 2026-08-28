import Foundation
import Observation

@MainActor
@Observable
final class RoutePlanningViewModel {
    private(set) var route: Route?
    private(set) var isPlanningRoute = false
    private(set) var routeError: Error?

    private let routePlanningService: any RoutePlanningService
    private var planningTask: Task<Route, Error>?
    private var planningRequestID: UUID?

    init(routePlanningService: any RoutePlanningService) {
        self.routePlanningService = routePlanningService
    }

    var nextStep: RouteStep? {
        route?.steps.first
    }

    func planRoute(to destination: Location, from origin: Location) async -> Route? {
        planningTask?.cancel()

        let requestID = UUID()
        let task = Task { [routePlanningService] in
            try await routePlanningService.planCyclingRoute(from: origin, to: destination)
        }
        planningRequestID = requestID
        planningTask = task
        route = nil
        isPlanningRoute = true
        routeError = nil

        do {
            let route = try await task.value
            guard planningRequestID == requestID else { return nil }

            self.route = route
            isPlanningRoute = false
            planningTask = nil
            return route
        } catch {
            guard planningRequestID == requestID else { return nil }

            routeError = error
            isPlanningRoute = false
            planningTask = nil
            return nil
        }
    }

    func clearRoute() {
        cancelPlanning()
        route = nil
        routeError = nil
    }

    func cancelPlanning() {
        planningTask?.cancel()
        planningTask = nil
        planningRequestID = nil
        isPlanningRoute = false
    }
}
