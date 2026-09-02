import Foundation

struct RouteBaselineProjection {
    let coordinate: LocationCoordinate
    let progressFromRouteStartMeters: Double
    let distanceFromQueryMeters: Double
}

struct RouteBaselineProjector {
    private let geometry = CyclingPathGeometry()

    func project(
        _ queryCoordinate: LocationCoordinate,
        onto routeCoordinates: [LocationCoordinate]
    ) -> RouteBaselineProjection? {
        guard routeCoordinates.count >= 2 else { return nil }

        var closestProjection: RouteBaselineProjection?
        var distanceBeforeCurrentEdgeMeters = 0.0

        for coordinateIndex in routeCoordinates.indices.dropLast() {
            let edgeStart = routeCoordinates[coordinateIndex]
            let edgeEnd = routeCoordinates[coordinateIndex + 1]
            guard let edgeProjection = geometry.projection(
                of: queryCoordinate,
                onto: edgeStart,
                and: edgeEnd
            ) else {
                continue
            }

            let candidateProjection = RouteBaselineProjection(
                coordinate: edgeProjection.coordinate,
                progressFromRouteStartMeters: distanceBeforeCurrentEdgeMeters
                    + edgeProjection.distanceFromEdgeStartMeters,
                distanceFromQueryMeters: edgeProjection.distanceFromQueryMeters
            )
            if closestProjection.map({
                candidateProjection.distanceFromQueryMeters < $0.distanceFromQueryMeters
            }) ?? true {
                closestProjection = candidateProjection
            }

            distanceBeforeCurrentEdgeMeters += geometry.distance(from: edgeStart, to: edgeEnd)
        }

        return closestProjection
    }
}
