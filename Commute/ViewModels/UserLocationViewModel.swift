import Observation


@MainActor
@Observable
final class UserLocationViewModel {
    private(set) var currentLocation: Location?
    private(set) var locationError: Error?
    private var observationTask: Task<Void, Never>?
    private var locationWaiters: [CheckedContinuation<Location?, Never>] = []

    func startObserving(using provider: LocationProvider) {
        guard observationTask == nil else { return }

        observationTask = Task { [weak self] in
            await self?.observeLocation(using: provider)
        }
    }

    func ensureCurrentLocation(using provider: LocationProvider) async {
        guard currentLocation == nil else { return }
        startObserving(using: provider)
        _ = await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
        }
    }

    private func observeLocation(using provider: LocationProvider) async {
        defer { observationTask = nil }

        do {
            for try await location in provider.locationStream() {
                currentLocation = location
                let waiters = locationWaiters
                locationWaiters.removeAll()
                waiters.forEach { $0.resume(returning: location) }
            }
        } catch is CancellationError {
            // expected when the view leaves the screen
        } catch {
            locationError = error
            finishLocationWaiters(with: nil)
        }
    }

    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
        finishLocationWaiters(with: nil)
    }

    private func finishLocationWaiters(with location: Location?) {
        let waiters = locationWaiters
        locationWaiters.removeAll()
        waiters.forEach { $0.resume(returning: location) }
    }
}
