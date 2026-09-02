import Foundation

@MainActor
final class CyclingPathSpatialIndex {
    private var segmentsByID: [String: CyclingPathSegment] = [:]
    private var segmentIDsByCell: [GridCell: Set<String>] = [:]

    func rebuild(with segments: [CyclingPathSegment]) {
        segmentsByID = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
        segmentIDsByCell.removeAll(keepingCapacity: true)

        for segment in segments {
            guard let bounds = segment.bounds else { continue }
            cells(in: bounds).forEach { cell in
                segmentIDsByCell[cell, default: []].insert(segment.id)
            }
        }
    }

    func candidateSegments(near coordinate: LocationCoordinate, within radiusMeters: Double) -> [CyclingPathSegment] {
        let bounds = searchBounds(around: coordinate, radiusMeters: radiusMeters)
        let identifiers = cells(in: bounds).reduce(into: Set<String>()) { identifiers, cell in
            identifiers.formUnion(segmentIDsByCell[cell] ?? [])
        }

        return identifiers.compactMap { segmentsByID[$0] }
    }

    func segments(intersecting bounds: CyclingPathBounds) -> [CyclingPathSegment] {
        let identifiers = cells(in: bounds).reduce(into: Set<String>()) { identifiers, cell in
            identifiers.formUnion(segmentIDsByCell[cell] ?? [])
        }

        return identifiers.compactMap { segmentsByID[$0] }
            .filter { $0.bounds?.intersects(bounds) ?? false }
            .sorted { $0.id < $1.id }
    }

    private func searchBounds(around coordinate: LocationCoordinate, radiusMeters: Double) -> CyclingPathBounds {
        let latitudeDelta = radiusMeters / Preferences.CyclingPaths.metersPerLatitudeDegree
        let longitudeScale = Preferences.CyclingPaths.metersPerLongitudeDegree(at: coordinate.latitude)
        let longitudeDelta = radiusMeters / longitudeScale

        return CyclingPathBounds(
            minimumLatitude: coordinate.latitude - latitudeDelta,
            maximumLatitude: coordinate.latitude + latitudeDelta,
            minimumLongitude: coordinate.longitude - longitudeDelta,
            maximumLongitude: coordinate.longitude + longitudeDelta
        )
    }

    private func cells(in bounds: CyclingPathBounds) -> [GridCell] {
        let minimumLatitude = gridValue(for: bounds.minimumLatitude)
        let maximumLatitude = gridValue(for: bounds.maximumLatitude)
        let minimumLongitude = gridValue(for: bounds.minimumLongitude)
        let maximumLongitude = gridValue(for: bounds.maximumLongitude)

        return (minimumLatitude...maximumLatitude).flatMap { latitude in
            (minimumLongitude...maximumLongitude).map { longitude in
                GridCell(latitude: latitude, longitude: longitude)
            }
        }
    }

    private func gridValue(for coordinate: Double) -> Int {
        Int(floor(coordinate / Preferences.CyclingPaths.spatialIndexCellSizeDegrees))
    }
}

private struct GridCell: Hashable {
    let latitude: Int
    let longitude: Int
}
