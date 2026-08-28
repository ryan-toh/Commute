import Foundation
import SwiftUI

struct RouteStepView: View {
    let state: UserRouteState
    let currentStep: RouteStep?
    let progress: RouteProgress?
    let error: Error?
    let onStopNavigation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Preferences.NavigationUI.controlsSpacing) {
            sessionContent

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

    @ViewBuilder
    private var sessionContent: some View {
        switch state {
        case .following:
            RouteInstructionView(step: currentStep)
            if let progress {
                Text(String(format: Preferences.NavigationUI.remainingDistanceFormat, progress.remainingDistanceMeters))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            stopButton
        case .rerouting:
            ProgressView(Preferences.NavigationUI.rerouting)
            stopButton
        case .arrived:
            Label(Preferences.NavigationUI.arrived, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Button(Preferences.NavigationUI.stopNavigation, action: onStopNavigation)
                .buttonStyle(.bordered)
        case .idle, .stopped:
            EmptyView()
        }
    }

    private var stopButton: some View {
        Button(Preferences.NavigationUI.stopNavigation, action: onStopNavigation)
            .buttonStyle(.bordered)
    }
}
