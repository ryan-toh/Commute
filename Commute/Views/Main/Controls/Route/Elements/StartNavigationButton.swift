import SwiftUI

/// Starts navigation using the planned route.
struct StartNavigationButton: View {
    let action: () -> Void

    var body: some View {
        Button(Preferences.NavigationUI.startNavigation, action: action)
            .buttonStyle(.borderedProminent)
    }
}
