//
//  PlaceSearchArea.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

/// Prioritise search results for an area
struct PlaceSearchArea: Codable, Hashable {
    let center: LocationCoordinate
    let latitudeDelta: Double
    let longitudeDelta: Double
}
