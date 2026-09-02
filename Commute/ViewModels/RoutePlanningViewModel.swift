import Foundation
import Observation

@MainActor
@Observable
final class RoutePlanningViewModel {
    private(set) var destination: Location?
    private(set) var route: Route?
    private(set) var isPlanningRoute = false
    private(set) var routeError: Error?
    private(set) var placeDetails: PlaceDetails?
    private(set) var isLoadingPlaceDetails = false
    private(set) var placeDetailsError: Error?

    private let routePlanningService: any RoutePlanningService
    private let placeDetailsService: any LocationDetailsService
    private var planningTask: Task<Route, Error>?
    private var planningRequestID: UUID?
    private var placeDetailsTask: Task<Void, Never>?
    private var placeDetailsRequestID: UUID?

    init(
        routePlanningService: any RoutePlanningService,
        placeDetailsService: any LocationDetailsService
    ) {
        self.routePlanningService = routePlanningService
        self.placeDetailsService = placeDetailsService
    }

    func selectDestination(_ destination: Location) {
        clearRoute()
        self.destination = destination
        loadPlaceDetails(for: destination)
    }

    func clearDestination() {
        clearRoute()
        clearPlaceDetails()
        destination = nil
    }

    func planRoute(from origin: Location) async -> Route? {
        guard let destination else { return nil }
        planningTask?.cancel()

        let requestID = UUID()
        let task = Task { [routePlanningService] in
            try await routePlanningService.planCyclingRoute(from: origin, to: destination)
        }
        planningRequestID = requestID
        planningTask = task
        route = nil
        isPlanningRoute = true
        routeError = nil

        do {
            let route = try await task.value
            guard planningRequestID == requestID else { return nil }

            self.route = route
            isPlanningRoute = false
            planningTask = nil
            return route
        } catch {
            guard planningRequestID == requestID else { return nil }

            routeError = error
            isPlanningRoute = false
            planningTask = nil
            return nil
        }
    }

    func clearRoute() {
        cancelPlanning()
        route = nil
        routeError = nil
    }

    func showPlanningError(_ error: Error) {
        cancelPlanning()
        route = nil
        routeError = error
    }

    func cancelPlanning() {
        planningTask?.cancel()
        planningTask = nil
        planningRequestID = nil
        isPlanningRoute = false
    }

    private func loadPlaceDetails(for destination: Location) {
        clearPlaceDetails()

        let requestID = UUID()
        placeDetailsRequestID = requestID
        placeDetails = PlaceDetails(location: destination)
        isLoadingPlaceDetails = true

        placeDetailsTask = Task { [placeDetailsService] in
            do {
                let details = try await placeDetailsService.details(for: destination)
                guard self.placeDetailsRequestID == requestID else { return }

                self.placeDetails = details
                self.isLoadingPlaceDetails = false
                self.placeDetailsTask = nil
            } catch is CancellationError {
                // A newer destination selection supersedes this request.
            } catch {
                guard self.placeDetailsRequestID == requestID else { return }

                self.placeDetailsError = error
                self.isLoadingPlaceDetails = false
                self.placeDetailsTask = nil
            }
        }
    }

    private func clearPlaceDetails() {
        placeDetailsRequestID = nil
        placeDetailsTask?.cancel()
        placeDetailsTask = nil
        placeDetails = nil
        isLoadingPlaceDetails = false
        placeDetailsError = nil
    }
}
