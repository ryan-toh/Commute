import Observation
import Foundation

@MainActor
@Observable
final class UserLocationViewModel {
    private(set) var currentLocation: Location?
    private(set) var locationError: Error?
    private var observationTask: Task<Void, Never>?
    private var observationID: UUID?
    private var locationWaiters: [CheckedContinuation<Location?, Never>] = []

    func startObserving(using provider: LocationProvider) {
        guard observationTask == nil else { return }

        let observationID = UUID()
        self.observationID = observationID
        observationTask = Task { [weak self] in
            await self?.observeLocation(using: provider, observationID: observationID)
        }
    }

    func ensureCurrentLocation(using provider: LocationProvider) async -> Location? {
        locationError = nil
        if let currentLocation { return currentLocation }

        switch provider.canAccessUserLocation {
        case .denied, .restricted:
            locationError = LocationAccessError.denied
            return nil
        case .notDetermined, .authorized:
            break
        }

        startObserving(using: provider)
        return await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
        }
    }

    private func observeLocation(using provider: LocationProvider, observationID: UUID) async {
        defer {
            if self.observationID == observationID {
                self.observationTask = nil
                self.observationID = nil
            }
        }

        do {
            for try await location in provider.locationStream() {
                switch provider.canAccessUserLocation {
                case .denied, .restricted:
                    finishLocationWaiters(with: nil)
                    return
                case .notDetermined, .authorized:
                    break
                }

                currentLocation = location
                locationError = nil
                let waiters = locationWaiters
                locationWaiters.removeAll()
                waiters.forEach { $0.resume(returning: location) }
            }
            if currentLocation == nil {
                locationError = accessError(for: provider)
            }
            finishLocationWaiters(with: nil)
        } catch is CancellationError {
            // expected when the view leaves the screen
        } catch {
            locationError = error
            finishLocationWaiters(with: nil)
        }
    }

    func stopObserving() {
        observationID = nil
        observationTask?.cancel()
        observationTask = nil
        finishLocationWaiters(with: nil)
    }

    private func finishLocationWaiters(with location: Location?) {
        let waiters = locationWaiters
        locationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: location) }
    }

    private func accessError(for provider: LocationProvider) -> LocationAccessError {
        switch provider.canAccessUserLocation {
        case .denied, .restricted:
            .denied
        case .notDetermined, .authorized:
            .unavailable
        }
    }
}
