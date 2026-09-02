//
//  UserLocationManager.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class UserLocationManager: UserLocationProvider {
    private(set) var canAccessUserLocation: LocationAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var updateTask: Task<Void, Never>?
    private var updateID: UUID?
    private var subscribers: [UUID: AsyncThrowingStream<Location, Error>.Continuation] = [:]

    init() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        canAccessUserLocation = authorizationStatus(from: manager.authorizationStatus)
    }

    func requestPermission() async {
        refreshAuthorizationStatus()
        guard canAccessUserLocation == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    // Each caller receives the same live Core Location stream. This type owns
    // authorization enforcement, so it never yields a location after access is revoked.
    func locationStream() -> AsyncThrowingStream<Location, Error> {
        refreshAuthorizationStatus()

        switch canAccessUserLocation {
        case .denied, .restricted:
            return AsyncThrowingStream { $0.finish() }
        case .notDetermined, .authorized:
            break
        }

        return AsyncThrowingStream { continuation in
            let subscriberID = UUID()
            subscribers[subscriberID] = continuation
            startUpdatesIfNeeded()

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.removeSubscriber(withID: subscriberID)
                }
            }
        }
    }

    private func startUpdatesIfNeeded() {
        guard updateTask == nil else { return }

        let updateID = UUID()
        self.updateID = updateID
        updateTask = Task { [weak self] in
            guard let self else { return }
            await requestPermission()
            await consumeLocationUpdates(updateID: updateID)
        }
    }

    private func consumeLocationUpdates(updateID: UUID) async {
        defer {
            if self.updateID == updateID {
                self.updateTask = nil
                self.updateID = nil
            }
        }

        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                updateAuthorization(for: update)

                switch canAccessUserLocation {
                case .denied, .restricted:
                    finishSubscribers()
                    return
                case .notDetermined, .authorized:
                    break
                }

                guard let location = makeLocation(from: update) else { continue }
                broadcast(location)
            }
            finishSubscribers()
        } catch {
            guard !Task.isCancelled else { return }
            finishSubscribers(throwing: error)
        }
    }

    private func broadcast(_ location: Location) {
        subscribers.values.forEach { $0.yield(location) }
    }

    private func removeSubscriber(withID id: UUID) {
        subscribers[id] = nil
        guard subscribers.isEmpty else { return }
        updateID = nil
        updateTask?.cancel()
        updateTask = nil
    }

    private func finishSubscribers(throwing error: Error) {
        let activeSubscribers = subscribers.values
        subscribers.removeAll()
        activeSubscribers.forEach { $0.finish(throwing: error) }
    }

    private func finishSubscribers() {
        let activeSubscribers = subscribers.values
        subscribers.removeAll()
        activeSubscribers.forEach { $0.finish() }
    }

    private func updateAuthorization(for update: CLLocationUpdate) {
        switch (update.authorizationDenied, update.authorizationRestricted) {
        case (true, _):
            canAccessUserLocation = .denied
        case (_, true):
            canAccessUserLocation = .restricted
        default:
            break
        }
    }

    private func makeLocation(from update: CLLocationUpdate) -> Location? {
        guard let location = update.location else { return nil }

        return Location(
            id: UUID(),
            coordinate: LocationCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            address: nil,
            name: Preferences.LocationService.currentLocationName,
            source: .gps,
            capturedAt: location.timestamp
        )
    }

    private func authorizationStatus(from status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        case .denied: .denied
        case .restricted: .restricted
        case .notDetermined: .notDetermined
        @unknown default: .restricted
        }
    }

    private func refreshAuthorizationStatus() {
        canAccessUserLocation = authorizationStatus(from: manager.authorizationStatus)
    }
}
