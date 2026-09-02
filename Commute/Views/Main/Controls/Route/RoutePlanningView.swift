import SwiftUI

struct RoutePlanningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let viewModel: RoutePlanningViewModel
    let onPlanRoute: () -> Void
    let onStartNavigation: () -> Void
    let onDismissDestination: () -> Void

    var body: some View {
        if let destination = viewModel.destination {
            planningPanel(for: destination)
        }
    }

    private func planningPanel(for destination: Location) -> some View {
        VStack(spacing: Preferences.NavigationUI.controlsSpacing) {
            HStack {
                Spacer()
                Button(action: onDismissDestination) {
                    Image(systemName: Preferences.PlaceDetail.closeSymbol)
                        .font(.system(size: Preferences.PlaceDetail.closeButtonSymbolSize, weight: .semibold))
                        .padding(Preferences.PlaceDetail.closeButtonPadding)
                        .liquidGlassSurface(in: Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel(Preferences.PlaceDetail.closeAccessibilityLabel)
            }

            SelectedPlaceCardView(
                details: viewModel.placeDetails ?? PlaceDetails(location: destination),
                route: viewModel.route,
                isLoading: viewModel.isLoadingPlaceDetails
            )

            planningContent

            if let error = viewModel.routeError {
                RoutePlanningErrorView(error: error)
                    .transition(errorTransition)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Preferences.NavigationUI.routeControlsPadding)
        .background {
            ContainerRelativeShape()
                .fill(.clear)
                .liquidGlassSurface(in: ContainerRelativeShape())
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(
            reduceMotion ? nil : Preferences.CyclingNavigation.panelTransitionAnimation,
            value: presentation
        )
    }

    @ViewBuilder
    private var planningContent: some View {
        if viewModel.isPlanningRoute {
            RoutePlanningProgressView()
                .transition(contentTransition)
        } else if viewModel.route != nil {
            StartNavigationButton(action: onStartNavigation)
                .transition(contentTransition)
        } else {
            PlanRouteButton(action: onPlanRoute)
                .transition(contentTransition)
        }
    }

    private var presentation: String {
        if viewModel.isPlanningRoute { return "planning" }
        if viewModel.route != nil { return "planned" }
        if viewModel.routeError != nil { return "error" }
        return "ready"
    }

    private var contentTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }

    private var errorTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
    }
}
