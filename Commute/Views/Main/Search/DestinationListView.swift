//
//  DestinationListView.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import SwiftUI

struct DestinationListView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let results: [Location]
    let onDestinationSelected: (Location) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Preferences.DestinationSearch.resultListSpacing) {
                ForEach(results) { result in
                    DestinationListItemView(
                        destination: result,
                        onDestinationSelected: onDestinationSelected
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxHeight: Preferences.DestinationSearch.resultsMaximumHeight)
        .animation(
            reduceMotion ? nil : Preferences.DestinationSearch.listExpansionAnimation,
            value: results.map(\.id)
        )
    }
}

#Preview {
    DestinationListView(results: []) {_ in }
}
