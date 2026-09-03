//
//  PlaceCardView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Renders rich selected-place data without owning place or route state.
struct PlaceCardView: View {
    // MARK: - Data In
    let details: PlaceDetails
    let route: Route?
    let isLoading: Bool

    var body: some View {
        VStack(spacing: Preferences.PlaceDetail.cardSpacing) {
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
    // MARK: - Data In
    let details: PlaceDetails
    let isLoading: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: Preferences.PlaceDetail.headerSpacing) {

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
                        .lineLimit(Preferences.PlaceDetail
                            .addressLineLimit)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct PlaceQuickActionsView: View {
    // MARK: - Data In
    let details: PlaceDetails

    var body: some View {
        HStack(spacing: Preferences.PlaceDetail.actionSpacing) {
            if let callURL = details.callURL {
                Link(destination: callURL) {
                    actionIcon(systemImage: Preferences.PlaceDetail.callSymbol)
                }
                .accessibilityLabel(Preferences.PlaceDetail.callLabel)
            }

            if let websiteURL = details.websiteURL {
                Link(destination: websiteURL) {
                    actionIcon(systemImage: Preferences.PlaceDetail.websiteSymbol)
                }
                .accessibilityLabel(Preferences.PlaceDetail.websiteLabel)
            }
        }
    }

    private func actionIcon(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: Preferences.PlaceDetail.actionSymbolSize, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Preferences.PlaceDetail.actionVerticalPadding)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Preferences.PlaceDetail.actionCornerRadius))
    }
}

private struct RoutePreviewView: View {
    // MARK: - Data In
    let route: Route

    var body: some View {
        Label {
            Text(routeSummary)
        } icon: {
            Image(systemName: Preferences.PlaceDetail.routeSummarySymbol)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    private var routeSummary: String {
        let distance = String(
            format: Preferences.PlaceDetail.distanceFormat,
            route.distanceMeters / 1_000
        )
        let minutes = Int((route.expectedTravelTime / 60).rounded())
        let duration = String(format: Preferences.PlaceDetail.durationFormat, minutes)
        let summary = "\(Preferences.PlaceDetail.routeLabel) · \(duration) · \(distance)"
        guard case let .indirect(remainingDistanceMeters) = route.arrival else {
            return summary
        }
        return "\(summary) · \(String(format: Preferences.PlaceDetail.nearbyDestinationFormat, Int(remainingDistanceMeters.rounded())))"
    }
}

#Preview {
    PlaceCardView(
        details: PlaceDetails(
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
        isLoading: true
    )
    .padding()
    .background(.regularMaterial)
}
