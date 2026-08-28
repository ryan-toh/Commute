import SwiftUI

/// Starts route planning for a selected destination.
struct PlanRouteButton: View {
    let action: () -> Void

    var body: some View {
        Button(Preferences.NavigationUI.planRoute, action: action)
        .buttonStyle(.borderedProminent)
    }
}
