import Foundation

/// A geographic area used to prioritize destination-search results.
struct LocationSearchArea: Codable, Hashable {
    let center: LocationCoordinate
    let latitudeDelta: Double
    let longitudeDelta: Double
}
