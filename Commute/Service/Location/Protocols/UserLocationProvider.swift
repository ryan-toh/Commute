//
//  UserLocationProvider.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

@MainActor
protocol UserLocationProvider {
    var canAccessUserLocation: LocationAuthorizationStatus { get }

    func requestPermission() async
    func locationStream() -> AsyncThrowingStream<Location, Error>
}

enum LocationAuthorizationStatus {
    case notDetermined, restricted, denied, authorized
}

enum LocationAccessError: LocalizedError {
    case unavailable
    case denied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            Preferences.LocationService.locationUnavailableMessage
        case .denied:
            Preferences.LocationService.locationAccessDeniedMessage
        }
    }
}
