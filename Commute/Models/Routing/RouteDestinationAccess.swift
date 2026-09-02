//
//  RouteDestinationAccess.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

enum RouteDestinationAccess: Codable, Hashable {
    case direct
    case indirect(remainingDistanceMeters: Double)
}
