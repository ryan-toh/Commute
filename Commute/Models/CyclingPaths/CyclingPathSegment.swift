//
//  CyclingPathSegment.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Foundation

struct CyclingPathSegment: Identifiable, Codable, Hashable {
    // Unique ID
    let id: String
    
    let name: String?
    let lengthMeters: Double?
    let coordinates: [LocationCoordinate]

    // Get a bounding box of the cycling path
    var bounds: CyclingPathBounds? {
        guard let firstCoordinate = coordinates.first else {
            return nil
        }

        var minimumLatitude = firstCoordinate.latitude
        var maximumLatitude = firstCoordinate.latitude
        var minimumLongitude = firstCoordinate.longitude
        var maximumLongitude = firstCoordinate.longitude

        for coordinate in coordinates.dropFirst() {
            minimumLatitude = min(minimumLatitude, coordinate.latitude)
            maximumLatitude = max(maximumLatitude, coordinate.latitude)
            minimumLongitude = min(minimumLongitude, coordinate.longitude)
            maximumLongitude = max(maximumLongitude, coordinate.longitude)
        }

        return CyclingPathBounds(
            minimumLatitude: minimumLatitude,
            maximumLatitude: maximumLatitude,
            minimumLongitude: minimumLongitude,
            maximumLongitude: maximumLongitude
        )
    }
}


