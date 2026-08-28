import Foundation
import SwiftUI

/// Presents the active navigation state and composes its focused controls.
struct RouteNavigationView: View {
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
            RouteProgressView(step: currentStep, progress: progress)
            StopNavigationButton(action: onStopNavigation)
        case .rerouting:
            ProgressView(Preferences.NavigationUI.rerouting)
            StopNavigationButton(action: onStopNavigation)
        case .arrived:
            Label(Preferences.NavigationUI.arrived, systemImage: Preferences.NavigationUI.arrivedSymbol)
                .foregroundStyle(.green)
        case .failed:
            StopNavigationButton(action: onStopNavigation)
        case .idle, .stopped:
            EmptyView()
        }
    }
}

private struct RouteProgressView: View {
    let step: RouteStep?
    let progress: RouteProgress?

    var body: some View {
        RouteStepView(step: step)

        if let progress {
            Text(String(format: Preferences.NavigationUI.remainingDistanceFormat, progress.remainingDistanceMeters))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StopNavigationButton: View {
    let action: () -> Void

    var body: some View {
        Button(Preferences.NavigationUI.stopNavigation, action: action)
            .buttonStyle(.bordered)
    }
}
