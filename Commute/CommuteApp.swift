//
//  CommuteApp.swift
//  Commute
//
//  Created by Ryan on 26/6/26.
//

import SwiftUI
import Observation

@main
struct CommuteApp: App {
    @State private var locationManager: UserLocationManager
    @State private var userLocationViewModel: UserLocationViewModel
    @State private var destinationSearchViewModel: DestinationSearchViewModel
    @State private var navigationViewModel: RoutePlanningViewModel
    @State private var navigationSessionViewModel: RouteNavigationViewModel

    init() {
        let locationManager = UserLocationManager()
        let userLocationViewModel = UserLocationViewModel()
        let routePlanningService = MapKitRoutePlanningService()
        let destinationSearchViewModel = DestinationSearchViewModel(
            destinationSearchService: MapKitDestinationSearchService()
        )
        let navigationViewModel = RoutePlanningViewModel(
            routePlanningService: routePlanningService,
            placeDetailsService: MapKitPlaceDetailsService()
        )
        let navigationSessionViewModel = RouteNavigationViewModel(
            routePlanningService: routePlanningService,
            routeProgressCalculator: RouteProgressCalculator()
        )

        _locationManager = State(initialValue: locationManager)
        _userLocationViewModel = State(initialValue: userLocationViewModel)
        _destinationSearchViewModel = State(initialValue: destinationSearchViewModel)
        _navigationViewModel = State(initialValue: navigationViewModel)
        _navigationSessionViewModel = State(initialValue: navigationSessionViewModel)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(locationManager)
                .environment(userLocationViewModel)
                .environment(destinationSearchViewModel)
                .environment(navigationViewModel)
                .environment(navigationSessionViewModel)
        }
    }
}
