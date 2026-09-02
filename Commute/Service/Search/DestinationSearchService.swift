//
//  DestinationSearchService.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

protocol DestinationSearchService {
    func searchDestinations(
        matching query: String,
        in area: PlaceSearchArea?
    ) async throws -> [Location]
}
