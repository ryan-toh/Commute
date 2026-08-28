import Foundation
import Observation

@MainActor
@Observable
final class NavigationSessionViewModel {
    private(set) var destination: Location?
    private(set) var activeRoute: Route?
    private(set) var state: UserRouteState = .idle
    private(set) var progress: RouteProgress?
    private(set) var navigationError: Error?

    private let routePlanningService: any RoutePlanningService
    private let routeProgressCalculator: any RouteProgressCalculating
    private var monitoringTask: Task<Void, Never>?
    private var lastRerouteDate: Date?

    init(
        routePlanningService: any RoutePlanningService,
        routeProgressCalculator: any RouteProgressCalculating
    ) {
        self.routePlanningService = routePlanningService
        self.routeProgressCalculator = routeProgressCalculator
    }

    var currentStep: RouteStep? {
        guard let activeRoute else { return nil }
        let index = progress?.currentStepIndex ?? 0
        return activeRoute.steps.indices.contains(index) ? activeRoute.steps[index] : nil
    }

    func selectDestination(_ destination: Location) {
        stopNavigation()
        self.destination = destination
        activeRoute = nil
        progress = nil
        navigationError = nil
        state = .idle
    }

    func prepare(route: Route) {
        activeRoute = route
        progress = nil
        navigationError = nil
        state = .idle
    }

    func startNavigation(using locationProvider: LocationProvider) {
        guard activeRoute != nil, destination != nil, monitoringTask == nil else { return }
        state = .following
        navigationError = nil

        monitoringTask = Task { [weak self] in
            await self?.monitorLocation(using: locationProvider)
        }
    }

    func stopNavigation() {
        monitoringTask?.cancel()
        monitoringTask = nil

        if state == .following || state == .rerouting || state == .failed {
            state = .stopped
        }
    }

    private func monitorLocation(using locationProvider: LocationProvider) async {
        defer { monitoringTask = nil }

        do {
            for try await location in locationProvider.locationStream() {
                await updateNavigation(for: location)
            }
        } catch is CancellationError {
            // Stopping navigation intentionally cancels this task.
        } catch {
            navigationError = error
            state = .failed
        }
    }

    private func updateNavigation(for location: Location) async {
        guard let activeRoute else { return }
        guard let routeProgress = routeProgressCalculator.progress(on: activeRoute, at: location) else { return }

        progress = routeProgress

        if routeProgress.remainingDistanceMeters <= Preferences.NavigationSession.arrivalThresholdMeters {
            state = .arrived
            stopNavigation()
            return
        }

        guard routeProgress.distanceFromRouteMeters > Preferences.NavigationSession.offRouteThresholdMeters else { return }
        guard state == .following, canReroute else { return }
        await reroute(from: location)
    }

    private var canReroute: Bool {
        guard let lastRerouteDate else { return true }
        return Date.now.timeIntervalSince(lastRerouteDate) >= Preferences.NavigationSession.minimumRerouteInterval
    }

    private func reroute(from origin: Location) async {
        guard let destination else { return }

        state = .rerouting
        lastRerouteDate = .now

        do {
            activeRoute = try await routePlanningService.planCyclingRoute(from: origin, to: destination)
            progress = nil
            state = .following
        } catch {
            navigationError = error
            state = .failed
        }
    }
}

enum UserRouteState: Equatable {
    case idle
    case following
    case rerouting
    case arrived
    case stopped
    case failed
}
