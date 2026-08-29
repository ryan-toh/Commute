import Foundation

struct RouteProgressCalculator: RouteProgressCalculatorService {
    func progress(
        on route: Route,
        at location: Location,
        after minimumRouteCoordinatePosition: Double?
    ) -> RouteProgress? {
        guard route.coordinates.count >= 2 else { return nil }

        let segments = route.coordinates.indices.dropLast().map {
            RouteSegment(start: route.coordinates[$0], end: route.coordinates[$0 + 1])
        }
        guard let closest = closestProjection(
            to: location.coordinate,
            on: segments,
            after: minimumRouteCoordinatePosition
        ) else { return nil }

        let completedDistance = segments.prefix(closest.segmentIndex)
            .reduce(0) { $0 + $1.lengthMeters } + closest.distanceAlongSegmentMeters
        let totalRouteDistance = segments.reduce(0) { $0 + $1.lengthMeters }
        let nextStep = nextStep(
            after: completedDistance,
            on: route,
            segments: segments
        )

        return RouteProgress(
            nearestRouteCoordinate: closest.coordinate,
            distanceFromRouteMeters: closest.distanceMeters,
            completedDistanceMeters: completedDistance,
            remainingDistanceMeters: max(0, totalRouteDistance - completedDistance),
            nextStepIndex: nextStep.index,
            distanceToNextStepMeters: nextStep.distanceMeters,
            routeCoordinatePosition: closest.routeCoordinatePosition
        )
    }

    private func closestProjection(
        to coordinate: LocationCoordinate,
        on segments: [RouteSegment],
        after minimumRouteCoordinatePosition: Double?
    ) -> RouteProjection? {
        segments.enumerated().compactMap { index, segment in
            segment.project(coordinate, segmentIndex: index)
        }
        .filter { projection in
            guard let minimumRouteCoordinatePosition else { return true }
            return projection.routeCoordinatePosition >= minimumRouteCoordinatePosition
        }
        .min(by: { $0.distanceMeters < $1.distanceMeters })
    }

    private func nextStep(
        after completedDistance: Double,
        on route: Route,
        segments: [RouteSegment]
    ) -> (index: Int, distanceMeters: Double) {
        guard !route.steps.isEmpty else { return (0, 0) }

        let routeDistanceAtCoordinate = routeDistanceIndex(segments: segments)
        let maneuverAdvanceDistance = Preferences.NavigationSession.maneuverAdvanceDistanceMeters

        for (index, step) in route.steps.enumerated() {
            let maneuverDistance = routeDistanceAtCoordinate[
                min(step.routeCoordinateIndex, routeDistanceAtCoordinate.count - 1)
            ]
            let distanceToManeuver = max(0, maneuverDistance - completedDistance)

            if distanceToManeuver > maneuverAdvanceDistance {
                return (index, distanceToManeuver)
            }
        }

        return (route.steps.count - 1, 0)
    }

    private func routeDistanceIndex(segments: [RouteSegment]) -> [Double] {
        segments.reduce(into: [0]) { distances, segment in
            distances.append(distances[distances.count - 1] + segment.lengthMeters)
        }
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
            segmentIndex: segmentIndex,
            routeCoordinatePosition: Double(segmentIndex) + projectionFactor
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
    let routeCoordinatePosition: Double
}

private extension Double {
    var radians: Double { self * .pi / 180 }
}
