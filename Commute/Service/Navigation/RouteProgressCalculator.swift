import Foundation

protocol RouteProgressCalculating {
    func progress(on route: Route, at location: Location) -> RouteProgress?
}

struct RouteProgressCalculator: RouteProgressCalculating {
    func progress(on route: Route, at location: Location) -> RouteProgress? {
        guard route.coordinates.count >= 2 else { return nil }

        let segments = route.coordinates.indices.dropLast().map {
            RouteSegment(start: route.coordinates[$0], end: route.coordinates[$0 + 1])
        }
        guard let closest = closestProjection(to: location.coordinate, on: segments) else { return nil }

        let completedDistance = segments.prefix(closest.segmentIndex)
            .reduce(0) { $0 + $1.lengthMeters } + closest.distanceAlongSegmentMeters
        let currentStepIndex = stepIndex(
            for: completedDistance,
            route: route,
            segments: segments
        )

        return RouteProgress(
            nearestRouteCoordinate: closest.coordinate,
            distanceFromRouteMeters: closest.distanceMeters,
            completedDistanceMeters: completedDistance,
            remainingDistanceMeters: max(0, route.distanceMeters - completedDistance),
            currentStepIndex: currentStepIndex
        )
    }

    private func closestProjection(
        to coordinate: LocationCoordinate,
        on segments: [RouteSegment]
    ) -> RouteProjection? {
        segments.enumerated().compactMap { index, segment in
            segment.project(coordinate, segmentIndex: index)
        }
        .min(by: { $0.distanceMeters < $1.distanceMeters })
    }

    private func stepIndex(
        for completedDistance: Double,
        route: Route,
        segments: [RouteSegment]
    ) -> Int {
        route.steps.enumerated().last { index, _ in
            distanceAlongRoute(to: route.steps[index].coordinate, segments: segments) <= completedDistance
        }?.offset ?? 0
    }

    private func distanceAlongRoute(to coordinate: LocationCoordinate, segments: [RouteSegment]) -> Double {
        guard let closest = closestProjection(to: coordinate, on: segments) else { return 0 }
        return segments.prefix(closest.segmentIndex).reduce(0) { $0 + $1.lengthMeters }
            + closest.distanceAlongSegmentMeters
    }
}

private struct RouteSegment {
    let start: LocationCoordinate
    let end: LocationCoordinate

    var lengthMeters: Double { distance(from: start, to: end) }

    func project(_ coordinate: LocationCoordinate, segmentIndex: Int) -> RouteProjection? {
        let referenceLatitude = coordinate.latitude.radians
        let metersPerLatitudeDegree = 111_132.0
        let metersPerLongitudeDegree = 111_320.0 * cos(referenceLatitude)

        let startPoint = point(start, relativeTo: coordinate, latitudeScale: metersPerLatitudeDegree, longitudeScale: metersPerLongitudeDegree)
        let endPoint = point(end, relativeTo: coordinate, latitudeScale: metersPerLatitudeDegree, longitudeScale: metersPerLongitudeDegree)
        let vector = (x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
        let squaredLength = vector.x * vector.x + vector.y * vector.y
        guard squaredLength > 0 else { return nil }

        let projectionFactor = max(0, min(1, -((startPoint.x * vector.x) + (startPoint.y * vector.y)) / squaredLength))
        let projectedPoint = (x: startPoint.x + vector.x * projectionFactor, y: startPoint.y + vector.y * projectionFactor)
        let projectedCoordinate = LocationCoordinate(
            latitude: coordinate.latitude + projectedPoint.y / metersPerLatitudeDegree,
            longitude: coordinate.longitude + projectedPoint.x / metersPerLongitudeDegree
        )

        return RouteProjection(
            coordinate: projectedCoordinate,
            distanceMeters: hypot(projectedPoint.x, projectedPoint.y),
            distanceAlongSegmentMeters: lengthMeters * projectionFactor,
            segmentIndex: segmentIndex
        )
    }

    private func point(
        _ coordinate: LocationCoordinate,
        relativeTo reference: LocationCoordinate,
        latitudeScale: Double,
        longitudeScale: Double
    ) -> (x: Double, y: Double) {
        (
            x: (coordinate.longitude - reference.longitude) * longitudeScale,
            y: (coordinate.latitude - reference.latitude) * latitudeScale
        )
    }

    private func distance(from first: LocationCoordinate, to second: LocationCoordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitudeDelta = (second.latitude - first.latitude).radians
        let longitudeDelta = (second.longitude - first.longitude).radians
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(first.latitude.radians) * cos(second.latitude.radians)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}

private struct RouteProjection {
    let coordinate: LocationCoordinate
    let distanceMeters: Double
    let distanceAlongSegmentMeters: Double
    let segmentIndex: Int
}

private extension Double {
    var radians: Double { self * .pi / 180 }
}
