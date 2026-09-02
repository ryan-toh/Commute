//
//  RoutePlanningServiceFactory.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

/// Combine MapKit routing with a Cycling Path Segment repository
@MainActor
enum RoutePlanningServiceFactory {
    static func make(using cyclingPathRepository: CyclingPathRepository) -> any RoutePlanningService {
        let mapKitService = MapKitRoutePlanningService()

        switch Preferences.RoutePlanning.selectedService {
        case .mapKit:
            return mapKitService
        case .cyclingPathAware:
            return CyclingPathRoutePlanningService(
                mapKitService: mapKitService,
                cyclingPathRepository: cyclingPathRepository
            )
        }
    }
}
