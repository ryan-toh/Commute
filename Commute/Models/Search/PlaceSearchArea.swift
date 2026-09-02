//
//  PlaceSearchArea.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//



import Foundation

/// A geographic area used to prioritize destination-search results.
struct PlaceSearchArea: Codable, Hashable {
    let center: LocationCoordinate
    let latitudeDelta: Double
    let longitudeDelta: Double
}
