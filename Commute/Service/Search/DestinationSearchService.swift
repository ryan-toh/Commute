import Foundation

protocol DestinationSearchService {
    func searchDestinations(
        matching query: String,
        in area: LocationSearchArea?
    ) async throws -> [Location]
}
