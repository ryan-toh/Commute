//
//  LocationSource.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

enum MapLayer: CaseIterable, Hashable, Identifiable {
    case cyclingPaths
    case route
    case destination
    case userLocation

    // each case is already distinct
    var id: Self { self }
}
