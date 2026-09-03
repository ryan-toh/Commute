//
//  ControlView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

struct ControlView: View {
    // MARK: - Data In
    let routePlanningViewModel: RoutePlanningViewModel
    let routeNavigationViewModel: RouteNavigationViewModel
    let onPlanRoute: () -> Void
    let onStartNavigation: () -> Void
    let onDestinationDismissed: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch routeNavigationViewModel.currentState {
            case .following, .rerouting, .arrived, .failed:
                RouteNavigationView(
                    state: routeNavigationViewModel.currentState,
                    currentStep: routeNavigationViewModel.currentStep,
                    progress: routeNavigationViewModel.progress,
                    error: routeNavigationViewModel.navigationError,
                    onStopNavigation: routeNavigationViewModel.stopNavigation
                )
            case .idle, .stopped:
                if routePlanningViewModel.destination != nil {
                    RoutePlanningView(
                        viewModel: routePlanningViewModel,
                        onPlanRoute: onPlanRoute,
                        onStartNavigation: onStartNavigation,
                        onDismissDestination: onDestinationDismissed
                    )
                    .onDisappear { routePlanningViewModel.cancelPlanning() }
                }
            }
        }
        .transition(panelTransition)
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routeNavigationViewModel.currentState
        )
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routePlanningViewModel.destination?.id
        )
    }

    private var panelTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

}
