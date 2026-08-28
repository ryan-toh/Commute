import SwiftUI

struct RoutePlanningPanel: View {
    let destination: Location
    let nextStep: RouteStep?
    let isPlanning: Bool
    let error: Error?
    let hasPlannedRoute: Bool
    let onPlanRoute: (Location) -> Void
    let onStartNavigation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Preferences.NavigationUI.controlsSpacing) {
            RouteInstructionView(step: nextStep)

            if isPlanning {
                ProgressView(Preferences.NavigationUI.planningRoute)
            } else if hasPlannedRoute {
                Button(Preferences.NavigationUI.startNavigation) {
                    onStartNavigation()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(Preferences.NavigationUI.planRoute) {
                    onPlanRoute(destination)
                }
                .buttonStyle(.borderedProminent)
            }

            if let error {
                Text(error.localizedDescription)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
    }
}
