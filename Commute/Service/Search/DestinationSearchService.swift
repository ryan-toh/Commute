import Foundation

protocol DestinationSearchService {
    func searchDestinations(
        matching query: String,
        in area: PlaceSearchArea?
    ) async throws -> [Location]
}
