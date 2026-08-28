import Foundation

struct Route: Identifiable, Codable, Hashable {
    let id: UUID
    let coordinates: [LocationCoordinate]
    let steps: [RouteStep]
    let distanceMeters: Double
    let expectedTravelTime: TimeInterval
    let transportMode: TransportMode
}

