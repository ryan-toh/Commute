import SwiftUI

/// Displays a route-planning failure.
struct RoutePlanningErrorView: View {
    
    // MARK: - Data In
    let error: Error

    var body: some View {
        Text(error.localizedDescription)
            .font(.footnote)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
