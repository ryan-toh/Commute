import SwiftUI

struct RouteStepView: View {
    let step: RouteStep?

    var body: some View {
        if let step {
            Label(step.instruction, systemImage: Preferences.NavigationUI.nextStepSymbol)
                .font(.headline)
            Text(String(format: Preferences.NavigationUI.stepDistanceFormat, step.distanceMeters))
                .foregroundStyle(.secondary)
        } else {
            Text(Preferences.NavigationUI.destinationSelected)
                .font(.headline)
        }
    }
}
