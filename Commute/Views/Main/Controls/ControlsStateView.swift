import SwiftUI

struct ControlsStateView: View {
    let displayState: RouteState
    let onPlanRoute: (Location) -> Void
    let onStartNavigation: () -> Void
    let onStopNavigation: () -> Void

    var body: some View {
        Group {
            if let destination = displayState.destination {
                controls(for: destination)
            } else {
                DestinationPromptView()
            }
        }
    }

    @ViewBuilder
    private func controls(for destination: Location) -> some View {
        switch displayState.sessionState {
        case .following, .rerouting, .arrived, .failed:
            RouteStepView(
                state: displayState.sessionState,
                currentStep: displayState.nextStep,
                progress: displayState.progress,
                error: displayState.navigationError,
                onStopNavigation: onStopNavigation
            )
        case .idle, .stopped:
            RoutePlanningPanel(
                destination: destination,
                nextStep: displayState.nextStep,
                isPlanning: displayState.isPlanningRoute,
                error: displayState.routeError,
                hasPlannedRoute: displayState.hasPlannedRoute,
                onPlanRoute: onPlanRoute,
                onStartNavigation: onStartNavigation
            )
        }
    }
}
