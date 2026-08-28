import SwiftUI

struct RouteInstructionView: View {
    let step: RouteStep?

    var body: some View {
        if let step {
            Label(step.instruction, systemImage: Preferences.NavigationUI.nextStepSymbol)
                .font(.headline)
            Text("\(Int(step.distanceMeters.rounded())) m")
                .foregroundStyle(.secondary)
        } else {
            Text(Preferences.NavigationUI.destinationSelected)
                .font(.headline)
        }
    }
}
