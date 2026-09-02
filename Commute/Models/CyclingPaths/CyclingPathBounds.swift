//
//  CyclingPathBounds.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Foundation

struct CyclingPathBounds: Codable, Hashable {
    let minimumLatitude: Double
    let maximumLatitude: Double
    let minimumLongitude: Double
    let maximumLongitude: Double

    func intersects(_ other: CyclingPathBounds) -> Bool {
        minimumLatitude <= other.maximumLatitude &&
            maximumLatitude >= other.minimumLatitude &&
            minimumLongitude <= other.maximumLongitude &&
            maximumLongitude >= other.minimumLongitude
    }
}
