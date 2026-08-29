import Foundation
import Observation

@MainActor
@Observable
final class DestinationSearchViewModel {
    var query = ""
    private(set) var results: [Location] = []
    private(set) var isSearching = false
    private(set) var searchError: Error?

    private let destinationSearchService: any DestinationSearchService
    private var searchTask: Task<Void, Never>?
    private var searchRequestID: UUID?
    private var searchArea: LocationSearchArea?

    init(destinationSearchService: any DestinationSearchService) {
        self.destinationSearchService = destinationSearchService
    }

    func updateSearchArea(_ area: LocationSearchArea) {
        searchArea = area
    }

    func search() {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            isSearching = false
            searchError = nil
            searchRequestID = nil
            return
        }

        let requestID = UUID()
        searchRequestID = requestID
        isSearching = true
        searchError = nil

        searchTask = Task { [destinationSearchService] in
            do {
                try await Task.sleep(for: .milliseconds(Preferences.DestinationSearch.searchDelayMilliseconds))
                try Task.checkCancellation()
                let results = try await destinationSearchService.searchDestinations(
                    matching: trimmedQuery,
                    in: searchArea
                )
                guard !Task.isCancelled, self.searchRequestID == requestID else { return }

                self.results = results
                self.isSearching = false
                self.searchTask = nil
            } catch is CancellationError {
                // A newer query replaces this search.
            } catch {
                guard self.searchRequestID == requestID else { return }

                self.results = []
                self.searchError = error
                self.isSearching = false
                self.searchTask = nil
            }
        }
    }

    func clear() {
        query = ""
        results = []
        isSearching = false
        searchError = nil
        searchRequestID = nil
        searchTask?.cancel()
        searchTask = nil
    }
}
