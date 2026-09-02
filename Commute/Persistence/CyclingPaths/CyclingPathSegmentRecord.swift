import Foundation
import SwiftData

@Model
final class CyclingPathSegmentRecord {
    @Attribute(.unique) var id: String
    var name: String?
    var lengthMeters: Double?
    var encodedCoordinates: Data
    var minimumLatitude: Double
    var maximumLatitude: Double
    var minimumLongitude: Double
    var maximumLongitude: Double

    init(segment: CyclingPathSegment) throws {
        guard let bounds = segment.bounds else {
            throw CyclingPathPersistenceError.invalidSegment
        }

        id = segment.id
        name = segment.name
        lengthMeters = segment.lengthMeters
        encodedCoordinates = try JSONEncoder().encode(segment.coordinates)
        minimumLatitude = bounds.minimumLatitude
        maximumLatitude = bounds.maximumLatitude
        minimumLongitude = bounds.minimumLongitude
        maximumLongitude = bounds.maximumLongitude
    }

    func makeSegment() throws -> CyclingPathSegment {
        CyclingPathSegment(
            id: id,
            name: name,
            lengthMeters: lengthMeters,
            coordinates: try JSONDecoder().decode([LocationCoordinate].self, from: encodedCoordinates)
        )
    }
}

enum CyclingPathPersistenceError: Error {
    case invalidSegment
}
