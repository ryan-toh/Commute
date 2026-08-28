import SwiftUI

struct ControlView: View {
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel

    private var routeState: RouteState {
        RouteState(
            destination: routeNavigationViewModel.destination,
            sessionState: routeNavigationViewModel.state,
            nextStep: routeNavigationViewModel.currentStep ?? routePlanningViewModel.nextStep,
            progress: routeNavigationViewModel.progress,
            isPlanningRoute: routePlanningViewModel.isPlanningRoute,
            routeError: routePlanningViewModel.routeError,
            navigationError: routeNavigationViewModel.navigationError,
            hasPlannedRoute: routeNavigationViewModel.activeRoute != nil
        )
    }

    var body: some View {
        if let destination = routeState.destination {
            switch routeState.sessionState {
            case .following, .rerouting, .arrived, .failed:
                RouteNavigationView(
                    state: routeState.sessionState,
                    currentStep: routeState.nextStep,
                    progress: routeState.progress,
                    error: routeState.navigationError,
                    onStopNavigation: routeNavigationViewModel.stopNavigation
                )
            case .idle, .stopped:
                RoutePlanningView(
                    destination: destination,
                    nextStep: routeState.nextStep,
                    isPlanning: routeState.isPlanningRoute,
                    error: routeState.routeError,
                    hasPlannedRoute: routeState.hasPlannedRoute
                )
            }
        } else {
            DestinationPromptView()
        }
    }
}
