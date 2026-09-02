//
//  Route.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

/// Represents a navigable route from a start coordinate to an end coordinate
struct Route: Identifiable, Codable, Hashable {
    let id: UUID
    let coordinates: [LocationCoordinate]
    let steps: [RouteStep]
    let distanceMeters: Double
    let expectedTravelTime: TimeInterval
    let transportMode: TransportMode
    let arrival: RouteDestinationAccess

    init(
        id: UUID,
        coordinates: [LocationCoordinate],
        steps: [RouteStep],
        distanceMeters: Double,
        expectedTravelTime: TimeInterval,
        transportMode: TransportMode,
        arrival: RouteDestinationAccess = .direct
    ) {
        self.id = id
        self.coordinates = coordinates
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.expectedTravelTime = expectedTravelTime
        self.transportMode = transportMode
        self.arrival = arrival
    }
}
