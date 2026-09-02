import SwiftUI

struct ControlView: View {
    let onDestinationDismissed: () -> Void
    let onNavigationStarted: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(UserLocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel

    var body: some View {
        Group {
            switch routeNavigationViewModel.state {
            case .following, .rerouting, .arrived, .failed:
                RouteNavigationView(
                    state: routeNavigationViewModel.state,
                    currentStep: routeNavigationViewModel.currentStep,
                    progress: routeNavigationViewModel.progress,
                    error: routeNavigationViewModel.navigationError,
                    onStopNavigation: routeNavigationViewModel.stopNavigation
                )
                .transition(panelTransition)
            case .idle, .stopped:
                if routePlanningViewModel.destination != nil {
                    RoutePlanningView(
                        viewModel: routePlanningViewModel,
                        onPlanRoute: planRoute,
                        onStartNavigation: startNavigation,
                        onDismissDestination: onDestinationDismissed
                    )
                    .transition(panelTransition)
                    .onDisappear { routePlanningViewModel.cancelPlanning() }
                }
            }
        }
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routeNavigationViewModel.state
        )
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routePlanningViewModel.destination?.id
        )
    }

    private var panelTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private func planRoute() {
        guard let origin = userLocationViewModel.currentLocation else {
            userLocationViewModel.reportLocationUnavailable(using: locationManager)
            if let error = userLocationViewModel.locationError {
                routePlanningViewModel.showPlanningError(error)
            }
            return
        }

        Task {
            await routePlanningViewModel.planRoute(from: origin)
        }
    }

    private func startNavigation() {
        guard let route = routePlanningViewModel.route,
              let destination = routePlanningViewModel.destination else { return }

        routeNavigationViewModel.startNavigation(
            with: route,
            to: destination,
            using: locationManager
        )
        onNavigationStarted()
    }
}
