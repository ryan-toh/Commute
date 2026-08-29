//
//  NavigationStep.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

struct RouteStep: Identifiable, Codable, Hashable {
    let id: UUID
    let instruction: String
    let maneuver: RouteManeuver
    let distanceMeters: Double
    let coordinate: LocationCoordinate
    let routeCoordinateIndex: Int
    let transportMode: TransportMode
    let source: RouteStepDataSource
}

enum RouteStepDataSource: String, Codable, Hashable {
    case mapKit
    case curatedPath
}
