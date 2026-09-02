//
//  RouteProgress.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

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
