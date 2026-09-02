//
//  RouteNavigationViewModel.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class RouteNavigationViewModel {
    // MARK: - Observable Data
    private(set) var destination: Location?
    private(set) var activeRoute: Route?
    private(set) var state: UserRouteState = .idle
    private(set) var progress: RouteProgress?
    private(set) var navigationError: Error?

    private let routePlanningService: any RoutePlanningService
    private let routeProgressCalculator: any RouteProgressCalculatorService
    private var monitoringTask: Task<Void, Never>?
    private var monitoringID: UUID?
    private var lastRerouteDate: Date?

    init(
        routePlanningService: any RoutePlanningService,
        routeProgressCalculator: any RouteProgressCalculatorService
    ) {
        self.routePlanningService = routePlanningService
        self.routeProgressCalculator = routeProgressCalculator
    }

    var currentStep: RouteStep? {
        guard let activeRoute else { return nil }
        let index = progress?.nextStepIndex ?? 0
        return activeRoute.steps.indices.contains(index) ? activeRoute.steps[index] : nil
    }

    func startNavigation(
        with route: Route,
        to destination: Location,
        using locationProvider: UserLocationProvider
    ) {
        // suspend current navigation session if any
        stopNavigation()
        
        // initial setup
        self.destination = destination
        activeRoute = route
        progress = nil
        navigationError = nil
        lastRerouteDate = nil
        state = .following
        
        // start navigation session
        let monitoringID = UUID()
        self.monitoringID = monitoringID
        monitoringTask = Task { [weak self] in
            await self?.monitorLocation(using: locationProvider, monitoringID: monitoringID)
        }
    }

    func stopNavigation() {
        // suspend navigation session if any
        monitoringID = nil
        monitoringTask?.cancel()
        monitoringTask = nil

        if state == .following || state == .rerouting || state == .failed {
            state = .stopped
        }
    }

    func clearNavigation() {
        // suspend navigation session if any
        monitoringID = nil
        monitoringTask?.cancel()
        monitoringTask = nil
        destination = nil
        activeRoute = nil
        progress = nil
        navigationError = nil
        lastRerouteDate = nil
        state = .idle
    }

    /**
        Gets the live location from a given UserLocationProvider and updates the current route progress.
        - parameter using UserLocationProvider
        - parameter monitoringID a unique ID identifying the current navigation session
     */
    private func monitorLocation(using locationProvider: UserLocationProvider, monitoringID: UUID) async {
        
        defer {
            // suspend navigation session
            if self.monitoringID == monitoringID {
                self.monitoringTask = nil
                self.monitoringID = nil
            }
        }

        do {
            for try await location in locationProvider.locationStream() {
                guard await updateNavigation(for: location, monitoringID: monitoringID) else { return }
            }
            
            guard self.monitoringID == monitoringID, !Task.isCancelled else { return }
            navigationError = locationAccessError(for: locationProvider)
            state = .failed
        } catch is CancellationError {
            // Stopping navigation intentionally cancels this task.
        } catch {
            guard self.monitoringID == monitoringID else { return }
            navigationError = error
            state = .failed
        }
    }

    private func updateNavigation(for location: Location, monitoringID: UUID) async -> Bool {
        // cannot update if:
        // 1. no navigation session
        // 2. there is no active route (rerouting)
        guard self.monitoringID == monitoringID, !Task.isCancelled else { return false }
        guard let activeRoute else { return false }
        
        // publish route progress
        guard let routeProgress = routeProgressCalculator.progress(
            on: activeRoute,
            at: location,
            after: progress?.routeCoordinatePosition
        ) else { return true }
        
        progress = routeProgress

        // stop updating if we arrive at destination
        if routeProgress.remainingDistanceMeters <= Preferences.NavigationSession.arrivalThresholdMeters {
            state = .arrived
            stopNavigation()
            return false
        }

        // reroute if we can reroute and are too far away
        let isOffRoute = routeProgress.distanceFromRouteMeters
            > Preferences.NavigationSession.offRouteThresholdMeters
        let isCurrentlyFollowingRoute = state == .following
            
        if isOffRoute, isCurrentlyFollowingRoute, canReroute {
            await reroute(from: location, monitoringID: monitoringID)
        }
        
        return state != .failed
    }

    private var canReroute: Bool {
        guard let lastRerouteDate else { return true }
        return Date.now.timeIntervalSince(lastRerouteDate) >= Preferences.NavigationSession.minimumRerouteInterval
    }
    
    private func reroute(from origin: Location, monitoringID: UUID) async {
        guard let destination else { return }

        state = .rerouting
        lastRerouteDate = .now

        do {
            let reroutedRoute = try await routePlanningService.planCyclingRoute(from: origin, to: destination)
            guard self.monitoringID == monitoringID, !Task.isCancelled else { return }

            activeRoute = reroutedRoute
            progress = nil
            state = .following
        } catch {
            guard self.monitoringID == monitoringID, !Task.isCancelled else { return }

            navigationError = error
            state = .failed
        }
    }

    private func locationAccessError(for provider: UserLocationProvider) -> LocationAccessError {
        switch provider.canAccessUserLocation {
        case .denied, .restricted:
            .denied
        case .notDetermined, .authorized:
            .unavailable
        }
    }
}
