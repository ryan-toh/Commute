import MapKit
import SwiftUI

/// Presents the complete navigation experience: map first, controls second.
struct MainView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(UserLocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(DestinationSearchViewModel.self) private var destinationSearchViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel
    @State private var mapViewModel = MapViewModel()
    @State private var isShowingLocationError = false
    @FocusState private var isSearchFocused: Bool
    @Namespace private var mapScope

    var body: some View {
        ZStack {
            MapView(
                mapViewModel: mapViewModel,
                mapScope: mapScope,
                onDestinationSelected: selectDestination,
                onDestinationDismissed: dismissDestination,
                onVisibleSearchAreaChanged: destinationSearchViewModel.updateSearchArea
            )

            VStack(alignment: .trailing, spacing: 0) {
                if !routeNavigationViewModel.state.isNavigating {
                    DestinationSearchView(
                        viewModel: destinationSearchViewModel,
                        isSearchFocused: $isSearchFocused,
                        onDestinationSelected: selectDestination
                    )
                    .transition(.opacity)
                    .layoutPriority(0)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 0) {
                    Group {
                        if routeNavigationViewModel.state.isNavigating {
                            MapCompass(scope: mapScope)
                                .controlSize(.large)
                        }
                        RecenterButton(action: recenterMap)
                    }
                    .padding(.trailing, Preferences.NavigationUI.recenterButtonOuterPadding)
                    .padding(.bottom, Preferences.NavigationUI.recenterButtonOuterPadding)

                    if !isSearchFocused {
                        ControlView(
                            onDestinationDismissed: dismissDestination,
                            onNavigationStarted: beginNavigationMapFollowing
                        )
                            .transition(.opacity)
                    }
                }

                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .mapScope(mapScope)
        .onAppear {
            userLocationViewModel.startObserving(using: locationManager)
        }
        .onDisappear {
            userLocationViewModel.stopObserving()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            userLocationViewModel.startObserving(using: locationManager)
        }
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routeNavigationViewModel.state.isNavigating
        )
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: isSearchFocused
        )
        .alert(Preferences.LocationService.locationUnavailableTitle, isPresented: $isShowingLocationError) {
            Button(Preferences.LocationService.dismissButtonTitle, role: .cancel) {}
        } message: {
            Text(userLocationViewModel.locationError?.localizedDescription ?? Preferences.LocationService.locationUnavailableMessage)
        }
    }

    private func selectDestination(_ destination: Location) {
        routeNavigationViewModel.clearNavigation()
        routePlanningViewModel.selectDestination(destination)
    }

    private func dismissDestination() {
        withAnimation(Preferences.Motion.overlayTransitionAnimation) {
            routeNavigationViewModel.clearNavigation()
            routePlanningViewModel.clearDestination()
        }
    }

    private func recenterMap() {
        guard let coordinate = userLocationViewModel.currentLocation?.coordinate else {
            userLocationViewModel.reportLocationUnavailable(using: locationManager)
            isShowingLocationError = true
            return
        }

        if routeNavigationViewModel.state.isNavigating {
            mapViewModel.followUserHeading(from: coordinate)
        } else {
            mapViewModel.recenter(on: coordinate)
        }
    }

    private func beginNavigationMapFollowing() {
        guard let coordinate = userLocationViewModel.currentLocation?.coordinate else { return }
        mapViewModel.followUserHeading(from: coordinate)
    }
}

#Preview {
    let locationManager = UserLocationManager()
    let userLocationViewModel = UserLocationViewModel()
    let destinationSearchViewModel = DestinationSearchViewModel(
        destinationSearchService: MapKitDestinationSearchService()
    )
    let routePlanningService = MapKitRoutePlanningService()
    let navigationRouteViewModel = RoutePlanningViewModel(
        routePlanningService: routePlanningService,
        placeDetailsService: MapKitPlaceDetailsService()
    )
    let navigationSessionViewModel = RouteNavigationViewModel(
        routePlanningService: routePlanningService,
        routeProgressCalculator: RouteProgressCalculator()
    )
    
    MainView()
        .environment(locationManager)
        .environment(userLocationViewModel)
        .environment(destinationSearchViewModel)
        .environment(navigationRouteViewModel)
        .environment(navigationSessionViewModel)
}
