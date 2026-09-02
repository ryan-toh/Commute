import SwiftUI

/// Provides a large, deliberate control for ending an active cycling session.
struct EndNavigationButton: View {
    
    // MARK: - Data In
    let action: () -> Void

    var body: some View {
        RouteActionButton(
            title: Preferences.NavigationUI.stopNavigation,
            symbolName: Preferences.CyclingNavigation.endNavigationSymbol,
            tint: .red,
            action: action
        )
    }
}
