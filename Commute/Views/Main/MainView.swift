import SwiftUI

/// Presents the complete navigation experience: map first, controls second.
struct MainView: View {
    
    // MARK: Data In
    @Environment(LocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(NavigationRouteViewModel.self) private var navigationRouteViewModel
    @Environment(NavigationSessionViewModel.self) private var navigationSessionViewModel
    
    // MARK: Data owned by Me
    private var coordinator: MainCoordinator {
        MainCoordinator(
            locationManager: locationManager,
            userLocationViewModel: userLocationViewModel,
            navigationRouteViewModel: navigationRouteViewModel,
            navigationSessionViewModel: navigationSessionViewModel
        )
    }
    
    // MARK: Data owned by Me
    var displayState: MainScreenDisplayState {
        coordinator.displayState
    }
    
    // MARK: Data owned by Me
    var actions: MainScreenActions {
        coordinator.actions
    }

    var body: some View {
        MapView(
            userLocation: displayState.map.userLocation,
            route: displayState.map.route,
            destination: displayState.map.destination,
            requestingUserLocation: actions.map.requestUserLocation,
            onMapTap: actions.map.selectDestination
        )
            .safeAreaInset(edge: .bottom) {
                ControlView(
                    displayState: displayState.controls,
                    actions: actions.controls
                )
            }
            .task { coordinator.startObservingUserLocation() }
    }
}

#Preview {
    let locationManager = LocationManager()
    let userLocationViewModel = UserLocationViewModel()
    let routePlanningService = MapKitRoutePlanningService()
    let navigationRouteViewModel = NavigationRouteViewModel(routePlanningService: routePlanningService)
    let navigationSessionViewModel = NavigationSessionViewModel(
        routePlanningService: routePlanningService,
        routeProgressCalculator: RouteProgressCalculator()
    )
    
    MainView()
        .environment(locationManager)
        .environment(userLocationViewModel)
        .environment(navigationRouteViewModel)
        .environment(navigationSessionViewModel)
}
