import Foundation

struct RouteProgress: Codable, Hashable {
    let nearestRouteCoordinate: LocationCoordinate
    let distanceFromRouteMeters: Double
    let completedDistanceMeters: Double
    let remainingDistanceMeters: Double
    let nextStepIndex: Int
    let distanceToNextStepMeters: Double
    let routeCoordinatePosition: Double
}
