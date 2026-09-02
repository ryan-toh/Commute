//
//  SearchField.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import SwiftUI


struct SearchFieldView: View {
    @Binding var query: String
    let isFocused: FocusState<Bool>.Binding
    let onQueryChanged: (String) -> Void

    var body: some View {
        GlassEffectContainer {
            TextField(Preferences.DestinationSearch.searchPrompt, text: $query)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .onChange(of: query) { _, query in
                    onQueryChanged(query)
                }
                .padding(.horizontal, Preferences.DestinationSearch.searchFieldHorizontalPadding)
                .padding(.vertical, Preferences.DestinationSearch.searchFieldVerticalPadding)
                .frame(maxWidth: .infinity)
                .liquidGlassSurface(in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}
