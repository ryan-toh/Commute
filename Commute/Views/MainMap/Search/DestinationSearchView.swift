//
//  DestinationSearchView.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import SwiftUI

struct DestinationSearchView: View {
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // MARK: - Data In
    let viewModel: DestinationSearchViewModel
    let isSearchFocused: FocusState<Bool>.Binding
    let onDestinationSelected: (Location) -> Void

    var body: some View {
        @Bindable var destinationSearchViewModel = viewModel

        VStack(alignment: .leading, spacing: Preferences.DestinationSearch.overlaySpacing) {
            SearchFieldView(
                query: $destinationSearchViewModel.query,
                isFocused: isSearchFocused,
                onQueryChanged: { _ in viewModel.search() }
            )

            if hasSearchContent {
                searchContentContainer
            }
        }
        .padding(Preferences.DestinationSearch.overlayPadding)
        .padding(Preferences.DestinationSearch.containerPadding)
        .frame(maxWidth: Preferences.DestinationSearch.maximumContentWidth)
        .animation(
            reduceMotion ? nil : Preferences.DestinationSearch.contentAppearAnimation,
            value: hasSearchContent
        )
        .animation(
            reduceMotion ? nil : Preferences.DestinationSearch.listExpansionAnimation,
            value: searchContentLayoutID
        )
        .onDisappear {
            viewModel.clear()
        }
    }

    private var hasSearchContent: Bool {
        viewModel.isSearching ||
        viewModel.searchError != nil ||
        !viewModel.query.isEmpty
    }

    /// Identifies content changes that alter the panel's height so its layout springs smoothly.
    private var searchContentLayoutID: String {
        if viewModel.isSearching { return "searching" }
        if viewModel.searchError != nil { return "error" }
        if viewModel.results.isEmpty { return "empty" }
        return viewModel.results.map(\.id.uuidString).joined(separator: ",")
    }

    @ViewBuilder
    private var searchContentContainer: some View {
        if viewModel.isSearching {
            searchContent
                .transition(searchContentTransition)
        } else {
            searchContent
                .padding(Preferences.DestinationSearch.contentPadding)
                .frame(maxWidth: .infinity)
                .liquidGlassSurface(
                    in: RoundedRectangle(cornerRadius: Preferences.DestinationSearch.containerCornerRadius)
                )
                .transition(searchContentTransition)
        }
    }

    private var searchContentTransition: AnyTransition {
        .opacity
            .combined(with: .scale(scale: Preferences.DestinationSearch.contentAppearScale, anchor: .top))
            .combined(with: .move(edge: .top))
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.isSearching {
            HStack {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                    .padding(Preferences.DestinationSearch.searchLoadingIndicatorPadding)
                    .liquidGlassSurface(in: Circle())
                Spacer()
            }
                .frame(height: Preferences.DestinationSearch.searchLoadingHeight)
        } else if let error = viewModel.searchError {
            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundStyle(.red)
                .padding(.top, Preferences.DestinationSearch.contentTopPadding)
        } else if !viewModel.query.isEmpty {
            if viewModel.results.isEmpty {
                Text(Preferences.DestinationSearch.noResultsMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, Preferences.DestinationSearch.contentTopPadding)
            } else {
                DestinationListView(
                    results: viewModel.results,
                    onDestinationSelected: selectDestination
                )
            }
        }
    }

    private func selectDestination(_ destination: Location) {
        onDestinationSelected(destination)
        viewModel.clear()
        isSearchFocused.wrappedValue = false
    }
}

#Preview {
    @Previewable @FocusState var isSearchFocused: Bool
    let destinationSearchViewModel = DestinationSearchViewModel(destinationSearchService: MapKitDestinationSearchService())
    
    DestinationSearchView(
        viewModel: destinationSearchViewModel,
        isSearchFocused: $isSearchFocused,
        onDestinationSelected: { _ in }
    )
}
