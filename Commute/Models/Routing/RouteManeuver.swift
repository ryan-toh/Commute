import Foundation

/// A framework-independent description of the direction required for a route step.
enum RouteManeuver: String, Codable, Hashable {
    case straight
    case slightLeft
    case left
    case sharpLeft
    case slightRight
    case right
    case sharpRight
    case uTurn
    case arrive
    case unknown
}
