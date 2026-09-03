//
//  DestinationListView.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import SwiftUI

struct DestinationListView: View {
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let results: [Location]
    let onDestinationSelected: (Location) -> Void

    var body: some View {
        ViewThatFits(in: .vertical) {
            destinationRows
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                destinationRows
            }
        }
        .animation(
            reduceMotion ? nil : Preferences.DestinationSearch.listExpansionAnimation,
            value: results.map(\.id)
        )
    }

    private var destinationRows: some View {
        LazyVStack(alignment: .leading, spacing: Preferences.DestinationSearch.resultListSpacing) {
            ForEach(results) { result in
                DestinationListItemView(
                    destination: result,
                    onDestinationSelected: onDestinationSelected
                )
                .transition(
                    reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
                )
            }
        }
    }
}

#Preview {
    DestinationListView(
        results: []
    ) { _ in }
}
