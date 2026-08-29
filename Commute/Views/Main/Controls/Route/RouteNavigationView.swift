import Foundation
import SwiftUI

/// Presents the active navigation state and composes its focused controls.
struct RouteNavigationView: View {
    
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: UserRouteState
    let currentStep: RouteStep?
    let progress: RouteProgress?
    let error: Error?
    let onStopNavigation: () -> Void

    var body: some View {
        VStack(spacing: Preferences.CyclingNavigation.panelSpacing) {
            sessionContent
        }
        .animation(
            reduceMotion ? nil : Preferences.CyclingNavigation.progressAppearAnimation,
            value: progress != nil
        )
        .animation(
            reduceMotion ? nil : Preferences.CyclingNavigation.panelTransitionAnimation,
            value: state
        )
        .animation(
            reduceMotion ? nil : Preferences.CyclingNavigation.maneuverTransitionAnimation,
            value: currentStep?.id
        )
        .frame(maxWidth: .infinity)
        .padding(Preferences.NavigationUI.routeControlsPadding)
        .background {
            ContainerRelativeShape()
                .fill(.clear)
                .liquidGlassSurface(in: ContainerRelativeShape())
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private var sessionContent: some View {
        switch state {
        case .following:
            RouteStepView(
                step: currentStep,
                distanceToManeuverMeters: progress?.distanceToNextStepMeters
            )
                .id(currentStep?.id)
                .transition(maneuverTransition)
            if let progress {
                RouteStepSummaryView(progress: progress)
                    .transition(.opacity)
            }
            EndNavigationButton(action: onStopNavigation)
        case .rerouting:
            NavigationStatusView(
                title: Preferences.NavigationUI.rerouting,
                symbolName: Preferences.CyclingNavigation.reroutingSymbol,
                symbolColor: .orange,
                showsProgress: true
            )
            .id(state)
            .transition(maneuverTransition)
            EndNavigationButton(action: onStopNavigation)
        case .arrived:
            NavigationStatusView(
                title: Preferences.NavigationUI.arrived,
                symbolName: Preferences.CyclingNavigation.arrivedSymbol,
                symbolColor: .green,
                showsProgress: false
            )
            .id(state)
            .transition(maneuverTransition)
        case .failed:
            NavigationStatusView(
                title: error?.localizedDescription ?? Preferences.CyclingNavigation.navigationFailedMessage,
                symbolName: Preferences.CyclingNavigation.failedSymbol,
                symbolColor: .red,
                showsProgress: false
            )
            .id(state)
            .transition(maneuverTransition)
            EndNavigationButton(action: onStopNavigation)
        case .idle, .stopped:
            EmptyView()
        }
    }

    private var maneuverTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }
}

#Preview {
    RouteNavigationView(
        state: .following,
        currentStep: RouteStep(
            id: UUID(),
            instruction: "Turn left onto Orchard Road",
            maneuver: .left,
            distanceMeters: 120,
            coordinate: LocationCoordinate(latitude: 1.3048, longitude: 103.8318),
            routeCoordinateIndex: 12,
            transportMode: .cycling,
            source: .curatedPath
        ),
        progress: RouteProgress(
            nearestRouteCoordinate: LocationCoordinate(latitude: 1.3020, longitude: 103.8320),
            distanceFromRouteMeters: 4,
            completedDistanceMeters: 1_800,
            remainingDistanceMeters: 2_400,
            nextStepIndex: 0,
            distanceToNextStepMeters: 350,
            routeCoordinatePosition: 12
        ),
        error: nil,
        onStopNavigation: {}
    )
}
