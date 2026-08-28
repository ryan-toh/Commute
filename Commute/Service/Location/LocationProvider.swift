//
//  LocationProvider.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

@MainActor
protocol LocationProvider {
    var canAccessUserLocation: LocationAuthorizationStatus { get }

    func requestPermission() async
    func locationStream() -> AsyncThrowingStream<Location, Error>
}

enum LocationAuthorizationStatus {
    case notDetermined, restricted, denied, authorized
}
