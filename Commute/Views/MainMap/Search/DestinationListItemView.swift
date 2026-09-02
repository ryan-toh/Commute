//
//  DestinationListItemView.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import SwiftUI

struct DestinationListItemView: View {
    let destination: Location
    let onDestinationSelected: (Location) -> Void

    var body: some View {
        Button {
            onDestinationSelected(destination)
        } label: {
            VStack(alignment: .leading, spacing: Preferences.DestinationSearch.resultItemSpacing) {
                Text(destination.name ?? Preferences.DestinationSearch.searchPrompt)
                    .foregroundStyle(.primary)
                if let address = destination.address?.formatted, !address.isEmpty {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Preferences.DestinationSearch.resultItemVerticalPadding)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DestinationListItemView(destination: Location(id: UUID(), coordinate: LocationCoordinate(latitude: 1.3521, longitude: 103.8198), source: LocationSource.unknown, capturedAt: .now), onDestinationSelected: {_ in })
}
