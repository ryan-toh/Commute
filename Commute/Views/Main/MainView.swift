import SwiftUI

/// Presents the complete navigation experience: map first, controls second.
struct MainView: View {
    var body: some View {
        MapView()
            .safeAreaInset(edge: .bottom) {
                ControlView()
            }
    }
}

#Preview {
    let locationManager = LocationManager()
    let userLocationViewModel = UserLocationViewModel()
    let routePlanningService = MapKitRoutePlanningService()
    let navigationRouteViewModel = RoutePlanningViewModel(routePlanningService: routePlanningService)
    let navigationSessionViewModel = RouteNavigationViewModel(
        routePlanningService: routePlanningService,
        routeProgressCalculator: RouteProgressCalculator()
    )
    
    MainView()
        .environment(locationManager)
        .environment(userLocationViewModel)
        .environment(navigationRouteViewModel)
        .environment(navigationSessionViewModel)
}
