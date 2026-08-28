import Foundation

/// Coordinates navigation feature actions across shared application models.
@MainActor
struct MainCoordinator {
    private let locationManager: LocationManager
    private let userLocationViewModel: UserLocationViewModel
    private let navigationRouteViewModel: NavigationRouteViewModel
    private let navigationSessionViewModel: NavigationSessionViewModel

    init(
        locationManager: LocationManager,
        userLocationViewModel: UserLocationViewModel,
        navigationRouteViewModel: NavigationRouteViewModel,
        navigationSessionViewModel: NavigationSessionViewModel
    ) {
        self.locationManager = locationManager
        self.userLocationViewModel = userLocationViewModel
        self.navigationRouteViewModel = navigationRouteViewModel
        self.navigationSessionViewModel = navigationSessionViewModel
    }

    var displayState: MainScreenDisplayState {
        MainScreenDisplayState(
            map: MapDisplayState(
                userLocation: userLocationViewModel.currentLocation,
                route: navigationSessionViewModel.activeRoute ?? navigationRouteViewModel.route,
                destination: navigationSessionViewModel.destination
            ),
            controls: RouteState(
                destination: navigationSessionViewModel.destination,
                sessionState: navigationSessionViewModel.state,
                nextStep: navigationSessionViewModel.currentStep ?? navigationRouteViewModel.nextStep,
                progress: navigationSessionViewModel.progress,
                isPlanningRoute: navigationRouteViewModel.isPlanningRoute,
                routeError: navigationRouteViewModel.routeError,
                navigationError: navigationSessionViewModel.navigationError,
                hasPlannedRoute: navigationSessionViewModel.activeRoute != nil
            )
        )
    }

    var actions: MainScreenActions {
        MainScreenActions(
            map: MapActions(
                selectDestination: selectDestination,
                requestUserLocation: ensureCurrentUserLocation
            ),
            controls: NavigationControls(
                planRoute: planRoute,
                startNavigation: startNavigation,
                stopNavigation: stopNavigation
            )
        )
    }

    func startObservingUserLocation() {
        userLocationViewModel.startObserving(using: locationManager)
    }

    func ensureCurrentUserLocation() async {
        await userLocationViewModel.ensureCurrentLocation(using: locationManager)
    }

    func selectDestination(_ coordinate: LocationCoordinate) {
        let destination = Location(
            id: UUID(),
            coordinate: coordinate,
            address: nil,
            name: Preferences.NavigationUI.selectedDestinationName,
            source: .mapSelection,
            capturedAt: .now
        )

        navigationSessionViewModel.selectDestination(destination)
        navigationRouteViewModel.clearRoute()
    }

    func planRoute(to destination: Location) {
        Task {
            await ensureCurrentUserLocation()
            guard let origin = userLocationViewModel.currentLocation else { return }

            await navigationRouteViewModel.planRoute(to: destination, from: origin)
            guard let route = navigationRouteViewModel.route else { return }
            navigationSessionViewModel.prepare(route: route)
        }
    }

    func startNavigation() {
        navigationSessionViewModel.startNavigation(using: locationManager)
    }

    func stopNavigation() {
        navigationSessionViewModel.stopNavigation()
    }
}
