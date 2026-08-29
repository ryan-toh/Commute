import SwiftUI

/// Renders rich selected-place data without owning place or route state.
struct SelectedPlaceCardView: View {
    
    // MARK: - Data In
    let details: LocationDetails
    let route: Route?
    let isLoading: Bool

    var body: some View {
        VStack(spacing: Preferences.PlaceDetails.cardSpacing) {
            PlaceHeaderView(details: details, isLoading: isLoading)
            PlaceQuickActionsView(details: details)

            
            if let route {
                RoutePreviewView(route: route)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PlaceHeaderView: View {
    let details: LocationDetails
    let isLoading: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: Preferences.PlaceDetails.headerSpacing) {
                Text(details.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                if let categoryName = details.categoryName {
                    Text(categoryName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let address = details.address {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(Preferences.PlaceDetails.addressLineLimit)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(Preferences.PlaceDetails.loadingSymbol)
            }
        }
    }
}

private struct PlaceQuickActionsView: View {
    let details: LocationDetails

    var body: some View {
        HStack(spacing: Preferences.PlaceDetails.actionSpacing) {
            if let callURL = details.callURL {
                Link(destination: callURL) {
                    actionIcon(systemImage: Preferences.PlaceDetails.callSymbol)
                }
                .accessibilityLabel(Preferences.PlaceDetails.callLabel)
            }

            if let websiteURL = details.websiteURL {
                Link(destination: websiteURL) {
                    actionIcon(systemImage: Preferences.PlaceDetails.websiteSymbol)
                }
                .accessibilityLabel(Preferences.PlaceDetails.websiteLabel)
            }
        }
    }

    private func actionIcon(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Preferences.PlaceDetails.actionSymbolSize, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Preferences.PlaceDetails.actionVerticalPadding)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Preferences.PlaceDetails.actionCornerRadius))
    }
}

private struct RoutePreviewView: View {
    let route: Route

    var body: some View {
        Label {
            Text(routeSummary)
        } icon: {
            Image(systemName: Preferences.PlaceDetails.routeSummarySymbol)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    private var routeSummary: String {
        let distance = String(
            format: Preferences.PlaceDetails.distanceFormat,
            route.distanceMeters / 1_000
        )
        let minutes = Int((route.expectedTravelTime / 60).rounded())
        let duration = String(format: Preferences.PlaceDetails.durationFormat, minutes)
        return "\(Preferences.PlaceDetails.routeLabel) · \(duration) · \(distance)"
    }
}

#Preview {
    SelectedPlaceCardView(
        details: LocationDetails(
            name: "SHP – Punggol",
            address: "21 Punggol Field, Singapore 828450",
            categoryName: "Medical Centre",
            phoneNumber: "+65 6315 8188",
            websiteURL: URL(string: "https://www.singhealth.com.sg")
        ),
        route: Route(
            id: UUID(),
            coordinates: [
                LocationCoordinate(latitude: 1.4050, longitude: 103.9020),
                LocationCoordinate(latitude: 1.4070, longitude: 103.9040)
            ],
            steps: [],
            distanceMeters: 1_700,
            expectedTravelTime: 1_380,
            transportMode: .cycling
        ),
        isLoading: false
    )
    .padding()
    .background(.regularMaterial)
}
