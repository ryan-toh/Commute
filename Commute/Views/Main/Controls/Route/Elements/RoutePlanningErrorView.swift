import SwiftUI

/// Displays a route-planning failure.
struct RoutePlanningErrorView: View {
    let error: Error

    var body: some View {
        Text(error.localizedDescription)
            .font(.footnote)
            .foregroundStyle(.red)
    }
}
