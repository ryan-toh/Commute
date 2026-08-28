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
        Route(
            id: UUID(),
            coordinates: coordinates(from: route.polyline),
            steps: route.steps.map(makeNavigationStep),
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            transportMode: .cycling
        )
    }

    private func makeNavigationStep(from step: MKRoute.Step) -> RouteStep {
        RouteStep(
            id: UUID(),
            instruction: step.instructions.isEmpty ? "Continue" : step.instructions,
            distanceMeters: step.distance,
            coordinate: coordinate(from: step.polyline.coordinate),
            transportMode: .cycling,
            source: .mapKit
        )
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

    private func coordinate(from coordinate: CLLocationCoordinate2D) -> LocationCoordinate {
        LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
