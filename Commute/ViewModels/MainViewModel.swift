//
//  MapLayerViewModel.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Observation
import SwiftUI

/// Coordinates actions that cross the map, search, route-planning, and navigation features.
@MainActor
@Observable
final class MainViewModel {
    private(set) var isShowingLocationError = false

    let locationManager: UserLocationManager
    let userLocationViewModel: UserLocationViewModel
    let destinationSearchViewModel: DestinationSearchViewModel
    let cyclingPathRepository: CyclingPathRepository
    let mapLayerViewModel: MapLayerViewModel
    let routePlanningViewModel: RoutePlanningViewModel
    let routeNavigationViewModel: RouteNavigationViewModel

    init(
        locationManager: UserLocationManager,
        userLocationViewModel: UserLocationViewModel,
        destinationSearchViewModel: DestinationSearchViewModel,
        cyclingPathRepository: CyclingPathRepository,
        mapLayerViewModel: MapLayerViewModel,
        routePlanningViewModel: RoutePlanningViewModel,
        routeNavigationViewModel: RouteNavigationViewModel
    ) {
        self.locationManager = locationManager
        self.userLocationViewModel = userLocationViewModel
        self.destinationSearchViewModel = destinationSearchViewModel
        self.cyclingPathRepository = cyclingPathRepository
        self.mapLayerViewModel = mapLayerViewModel
        self.routePlanningViewModel = routePlanningViewModel
        self.routeNavigationViewModel = routeNavigationViewModel
    }

    func selectDestination(_ destination: Location) {
        routeNavigationViewModel.clearNavigation()
        routePlanningViewModel.selectDestination(destination)
    }

    func dismissDestination() {
        withAnimation(Preferences.Motion.overlayTransitionAnimation) {
            routeNavigationViewModel.clearNavigation()
            routePlanningViewModel.clearDestination()
        }
    }

    func planRoute() {
        guard let origin = userLocationViewModel.currentLocation else {
            userLocationViewModel.reportLocationUnavailable(using: locationManager)
            if let locationError = userLocationViewModel.locationError {
                routePlanningViewModel.showPlanningError(locationError)
            }
            return
        }

        Task {
            await routePlanningViewModel.planRoute(from: origin)
        }
    }

    func startNavigation(using mapViewModel: MapViewModel) {
        guard let route = routePlanningViewModel.route,
              let destination = routePlanningViewModel.destination else {
            return
        }

        routeNavigationViewModel.startNavigation(
            with: route,
            to: destination,
            using: locationManager
        )
        followUserHeading(using: mapViewModel)
    }

    func recenterMap(using mapViewModel: MapViewModel) {
        guard let currentCoordinate = userLocationViewModel.currentLocation?.coordinate else {
            userLocationViewModel.reportLocationUnavailable(using: locationManager)
            isShowingLocationError = true
            return
        }

        if routeNavigationViewModel.currentState.isNavigating {
            mapViewModel.followUserHeading(from: currentCoordinate)
        } else {
            mapViewModel.recenter(on: currentCoordinate)
        }
    }

    func startObservingUserLocation() {
        userLocationViewModel.startObserving(using: locationManager)
    }

    func stopObservingUserLocation() {
        userLocationViewModel.stopObserving()
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        guard scenePhase == .active else { return }
        startObservingUserLocation()
    }

    func prepareCyclingPathData(visibleSearchArea: PlaceSearchArea?) async {
        try? await cyclingPathRepository.prepareForUse()
        updateCyclingPathLayer(for: visibleSearchArea)
    }

    func updateVisibleSearchArea(_ visibleSearchArea: PlaceSearchArea) {
        destinationSearchViewModel.updateSearchArea(visibleSearchArea)
        updateCyclingPathLayer(for: visibleSearchArea)
    }

    func updateCyclingPathLayer(for visibleSearchArea: PlaceSearchArea?) {
        guard let visibleSearchArea else { return }
        mapLayerViewModel.updateVisibleArea(visibleSearchArea)
    }

    func dismissLocationError() {
        isShowingLocationError = false
    }

    private func followUserHeading(using mapViewModel: MapViewModel) {
        guard let currentCoordinate = userLocationViewModel.currentLocation?.coordinate else {
            return
        }
        mapViewModel.followUserHeading(from: currentCoordinate)
    }
}
