import Foundation

protocol RoutePlanningService {
    func planCyclingRoute(
        from origin: Location,
        to destination: Location
    ) async throws -> Route
}

enum RoutePlanningError: LocalizedError {
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .noRouteFound:
            Preferences.RoutePlanning.noRouteFoundMessage
        }
    }
}
