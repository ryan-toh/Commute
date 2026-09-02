import Foundation

struct CyclingPathGeometry {
    func distance(
        from firstCoordinate: LocationCoordinate,
        to secondCoordinate: LocationCoordinate
    ) -> Double {
        let latitudeDifference = secondCoordinate.latitude - firstCoordinate.latitude
        let longitudeDifference = secondCoordinate.longitude - firstCoordinate.longitude
        let averageLatitude = (firstCoordinate.latitude + secondCoordinate.latitude) / 2

        let latitudeDistance = latitudeDifference * Preferences.CyclingPaths.metersPerLatitudeDegree
        let longitudeDistance = longitudeDifference
            * Preferences.CyclingPaths.metersPerLongitudeDegree(at: averageLatitude)

        return hypot(latitudeDistance, longitudeDistance)
    }

    func length(of coordinates: [LocationCoordinate]) -> Double {
        guard coordinates.count >= 2 else { return 0 }

        var totalLengthMeters = 0.0
        for coordinateIndex in coordinates.indices.dropLast() {
            totalLengthMeters += distance(
                from: coordinates[coordinateIndex],
                to: coordinates[coordinateIndex + 1]
            )
        }
        return totalLengthMeters
    }

    func projection(
        of queryCoordinate: LocationCoordinate,
        onto edgeStart: LocationCoordinate,
        and edgeEnd: LocationCoordinate
    ) -> EdgeCoordinateProjection? {
        let referenceLatitude = (edgeStart.latitude + edgeEnd.latitude + queryCoordinate.latitude) / 3
        let longitudeMetersPerDegree = Preferences.CyclingPaths.metersPerLongitudeDegree(at: referenceLatitude)

        let edgeLongitudeMeters = (edgeEnd.longitude - edgeStart.longitude) * longitudeMetersPerDegree
        let edgeLatitudeMeters = (edgeEnd.latitude - edgeStart.latitude)
            * Preferences.CyclingPaths.metersPerLatitudeDegree
        let edgeLengthSquared = edgeLongitudeMeters * edgeLongitudeMeters
            + edgeLatitudeMeters * edgeLatitudeMeters
        guard edgeLengthSquared > 0 else { return nil }

        let queryLongitudeMeters = (queryCoordinate.longitude - edgeStart.longitude) * longitudeMetersPerDegree
        let queryLatitudeMeters = (queryCoordinate.latitude - edgeStart.latitude)
            * Preferences.CyclingPaths.metersPerLatitudeDegree
        let unboundedFraction = (
            queryLongitudeMeters * edgeLongitudeMeters
                + queryLatitudeMeters * edgeLatitudeMeters
        ) / edgeLengthSquared
        let fractionAlongEdge = min(max(unboundedFraction, 0), 1)
        let projectedCoordinate = LocationCoordinate(
            latitude: edgeStart.latitude
                + (edgeEnd.latitude - edgeStart.latitude) * fractionAlongEdge,
            longitude: edgeStart.longitude
                + (edgeEnd.longitude - edgeStart.longitude) * fractionAlongEdge
        )

        return EdgeCoordinateProjection(
            coordinate: projectedCoordinate,
            fractionAlongEdge: fractionAlongEdge,
            distanceFromQueryMeters: distance(from: queryCoordinate, to: projectedCoordinate),
            distanceFromEdgeStartMeters: sqrt(edgeLengthSquared) * fractionAlongEdge
        )
    }
}

struct EdgeCoordinateProjection {
    let coordinate: LocationCoordinate
    let fractionAlongEdge: Double
    let distanceFromQueryMeters: Double
    let distanceFromEdgeStartMeters: Double
}
