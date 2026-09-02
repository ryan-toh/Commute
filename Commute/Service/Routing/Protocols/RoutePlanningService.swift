//
//  RoutePlanningService.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

@MainActor
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
