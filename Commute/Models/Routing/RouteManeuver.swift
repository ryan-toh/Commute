//
//  RouteManeuver.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

enum RouteManeuver: String, Codable, Hashable {
    case straight
    case slightLeft
    case left
    case sharpLeft
    case slightRight
    case right
    case sharpRight
    case uTurn
    case arrive
    case unknown
}
