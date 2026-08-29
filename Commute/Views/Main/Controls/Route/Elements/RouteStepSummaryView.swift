import SwiftUI

/// Displays the remaining trip distance without competing with the next maneuver.
struct RouteStepSummaryView: View {
    
    // MARK: - Data In
    let progress: RouteProgress

    var body: some View {
        Label(
            String(format: Preferences.NavigationUI.remainingDistanceFormat, progress.remainingDistanceMeters),
            systemImage: Preferences.CyclingNavigation.remainingDistanceSymbol
        )
        .font(.headline)
        .foregroundStyle(.secondary)
    }
}
