import SwiftUI

struct RoutePlanningView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel

    let destination: Location
    let nextStep: RouteStep?
    let isPlanning: Bool
    let error: Error?
    let hasPlannedRoute: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Preferences.NavigationUI.controlsSpacing) {
            RouteStepView(step: nextStep)

            if isPlanning {
                RoutePlanningProgressView()
            } else if hasPlannedRoute {
                StartNavigationButton(action: startNavigation)
            } else {
                PlanRouteButton(action: planRoute)
            }

            if let error = error ?? userLocationViewModel.locationError {
                RoutePlanningErrorView(error: error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .onDisappear { routePlanningViewModel.cancelPlanning() }
    }

    private func planRoute() {
        Task {
            guard let origin = await userLocationViewModel.ensureCurrentLocation(using: locationManager) else { return }

            guard let route = await routePlanningViewModel.planRoute(to: destination, from: origin) else { return }
            routeNavigationViewModel.prepare(route: route)
        }
    }

    private func startNavigation() {
        routeNavigationViewModel.startNavigation(using: locationManager)
    }
}
