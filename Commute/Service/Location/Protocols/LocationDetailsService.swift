import Foundation

protocol LocationDetailsService {
    func details(for location: Location) async throws -> PlaceDetails
}
