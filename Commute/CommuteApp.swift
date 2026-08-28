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
    @State private var locationManager: LocationManager
    @State private var userLocationViewModel: UserLocationViewModel
    @State private var navigationViewModel: NavigationRouteViewModel
    @State private var navigationSessionViewModel: NavigationSessionViewModel

    init() {
        let locationManager = LocationManager()
        let userLocationViewModel = UserLocationViewModel()
        let routePlanningService = MapKitRoutePlanningService()
        let navigationViewModel = NavigationRouteViewModel(
            routePlanningService: routePlanningService
        )
        let navigationSessionViewModel = NavigationSessionViewModel(
            routePlanningService: routePlanningService,
            routeProgressCalculator: RouteProgressCalculator()
        )

        _locationManager = State(initialValue: locationManager)
        _userLocationViewModel = State(initialValue: userLocationViewModel)
        _navigationViewModel = State(initialValue: navigationViewModel)
        _navigationSessionViewModel = State(initialValue: navigationSessionViewModel)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(locationManager)
                .environment(userLocationViewModel)
                .environment(navigationViewModel)
                .environment(navigationSessionViewModel)
        }
    }
}
