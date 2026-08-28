import SwiftUI

/// Supplies feature actions to the bottom navigation controls.
struct ControlView: View {
    let displayState: RouteState
    let actions: NavigationControls

    var body: some View {
        ControlsStateView(
            displayState: displayState,
            onPlanRoute: actions.planRoute,
            onStartNavigation: actions.startNavigation,
            onStopNavigation: actions.stopNavigation
        )
    }
}
