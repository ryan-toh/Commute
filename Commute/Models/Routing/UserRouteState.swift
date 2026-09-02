//
//  UserRouteState.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//


import Foundation

enum UserRouteState: Equatable {
    case idle
    case following
    case rerouting
    case arrived
    case stopped
    case failed

    var isNavigating: Bool {
        self == .following || self == .rerouting
    }
}
