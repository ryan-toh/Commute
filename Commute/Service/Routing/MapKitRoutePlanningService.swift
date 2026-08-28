import CoreLocation
import MapKit

final class MapKitRoutePlanningService: RoutePlanningService {
    func planCyclingRoute(
        from origin: Location,
        to destination: Location
    ) async throws -> Route {
        let request = MKDirections.Request()
        request.source = mapItem(for: origin.coordinate)
        request.destination = mapItem(for: destination.coordinate)
        request.transportType = .cycling
        request.requestsAlternateRoutes = false

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw RoutePlanningError.noRouteFound
        }

        return makeNavigationRoute(from: route)
    }

    private func mapItem(for coordinate: LocationCoordinate) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return MKMapItem(
            location: CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            address: nil
        )
    }

    private func makeNavigationRoute(from route: MKRoute) -> Route {
        let routeCoordinates = coordinates(from: route.polyline)

        return Route(
            id: UUID(),
            coordinates: routeCoordinates,
            steps: makeNavigationSteps(from: route.steps, routeCoordinates: routeCoordinates),
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            transportMode: .cycling
        )
    }

    private func makeNavigationSteps(
        from steps: [MKRoute.Step],
        routeCoordinates: [LocationCoordinate]
    ) -> [RouteStep] {
        var searchStartIndex = 0

        return steps.map { step in
            let stepCoordinate = finalCoordinate(from: step.polyline)
            let routeCoordinateIndex = nearestRouteCoordinateIndex(
                to: stepCoordinate,
                in: routeCoordinates,
                startingAt: searchStartIndex
            )
            searchStartIndex = routeCoordinateIndex

            return RouteStep(
                id: UUID(),
                instruction: step.instructions.isEmpty ? Preferences.RoutePlanning.fallbackInstruction : step.instructions,
                distanceMeters: step.distance,
                coordinate: stepCoordinate,
                routeCoordinateIndex: routeCoordinateIndex,
                transportMode: .cycling,
                source: .mapKit
            )
        }
    }

    private func coordinates(from polyline: MKPolyline) -> [LocationCoordinate] {
        var coordinates = Array(
            repeating: kCLLocationCoordinate2DInvalid,
            count: polyline.pointCount
        )
        polyline.getCoordinates(
            &coordinates,
            range: NSRange(location: 0, length: polyline.pointCount)
        )
        return coordinates.map(coordinate(from:))
    }

    private func finalCoordinate(from polyline: MKPolyline) -> LocationCoordinate {
        guard polyline.pointCount > 0 else { return coordinate(from: polyline.coordinate) }

        var finalMapCoordinate = kCLLocationCoordinate2DInvalid
        polyline.getCoordinates(
            &finalMapCoordinate,
            range: NSRange(location: polyline.pointCount - 1, length: 1)
        )
        return coordinate(from: finalMapCoordinate)
    }

    private func nearestRouteCoordinateIndex(
        to target: LocationCoordinate,
        in routeCoordinates: [LocationCoordinate],
        startingAt startIndex: Int
    ) -> Int {
        guard !routeCoordinates.isEmpty else { return 0 }

        let clampedStartIndex = min(max(startIndex, 0), routeCoordinates.count - 1)
        return routeCoordinates.indices
            .dropFirst(clampedStartIndex)
            .min { coordinateDistanceSquared(routeCoordinates[$0], target) < coordinateDistanceSquared(routeCoordinates[$1], target) }
            ?? clampedStartIndex
    }

    private func coordinateDistanceSquared(_ first: LocationCoordinate, _ second: LocationCoordinate) -> Double {
        let latitudeDelta = first.latitude - second.latitude
        let longitudeDelta = first.longitude - second.longitude
        return latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta
    }

    private func coordinate(from coordinate: CLLocationCoordinate2D) -> LocationCoordinate {
        LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
