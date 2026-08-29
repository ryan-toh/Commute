import Observation
import Foundation

@MainActor
@Observable
final class UserLocationViewModel {
    private(set) var currentLocation: Location?
    private(set) var locationError: Error?
    private var observationTask: Task<Void, Never>?
    private var observationID: UUID?

    func startObserving(using provider: UserLocationProvider) {
        guard observationTask == nil else { return }

        let observationID = UUID()
        self.observationID = observationID
        observationTask = Task { [weak self] in
            await self?.observeLocation(using: provider, observationID: observationID)
        }
    }

    func reportLocationUnavailable(using provider: UserLocationProvider) {
        locationError = accessError(for: provider)
    }

    private func observeLocation(using provider: UserLocationProvider, observationID: UUID) async {
        defer {
            // check needed to prevent a cancelled previous observation
            // from cancelling the current running observation
            if self.observationID == observationID {
                self.observationTask = nil
                self.observationID = nil
            }
        }

        do {
            // The provider only yields locations while access remains available.
            for try await location in provider.locationStream() {
                currentLocation = location
                locationError = nil
            }
            if currentLocation == nil {
                locationError = accessError(for: provider)
            }
        } catch is CancellationError {
            // expected when the view leaves the screen
        } catch {
            locationError = error
        }
    }

    func stopObserving() {
        observationID = nil
        observationTask?.cancel()
        observationTask = nil
    }

    private func accessError(for provider: UserLocationProvider) -> LocationAccessError {
        switch provider.canAccessUserLocation {
        case .denied, .restricted:
            .denied
        case .notDetermined, .authorized:
            .unavailable
        }
    }
}
