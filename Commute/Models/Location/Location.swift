//
//  Location.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

struct Location: Identifiable, Codable, Hashable {
    let id: UUID
    var coordinate: LocationCoordinate
    var address: LocationAddress?
    var name: String?
    var source: LocationSource
    var capturedAt: Date
}
