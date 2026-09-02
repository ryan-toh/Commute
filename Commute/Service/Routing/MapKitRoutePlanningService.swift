//
//  MapKitRoutePlanningService.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import CoreLocation
import MapKit

/// Plan a Cycling route using MapKit APIs
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

        let response: MKDirections.Response
        do {
            response = try await MKDirections(request: request).calculate()
        } catch {
            if isPlacemarkNotFound(error) {
                throw RoutePlanningError.noRouteFound
            }
            throw error
        }
        guard let route = response.routes.first else {
            throw RoutePlanningError.noRouteFound
        }

        return makeNavigationRoute(from: route)
    }

    private func isPlacemarkNotFound(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == MKError.errorDomain &&
            error.code == Int(MKError.Code.placemarkNotFound.rawValue)
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
            let instruction = step.instructions.isEmpty
                ? Preferences.RoutePlanning.fallbackInstruction
                : step.instructions
            let stepCoordinate = finalCoordinate(from: step.polyline)
            let routeCoordinateIndex = nearestRouteCoordinateIndex(
                to: stepCoordinate,
                in: routeCoordinates,
                startingAt: searchStartIndex
            )
            searchStartIndex = routeCoordinateIndex

            return RouteStep(
                id: UUID(),
                instruction: instruction,
                maneuver: maneuver(from: instruction),
                distanceMeters: step.distance,
                coordinate: stepCoordinate,
                routeCoordinateIndex: routeCoordinateIndex,
                transportMode: .cycling,
                source: .mapKit
            )
        }
    }

    private func maneuver(from instruction: String) -> RouteManeuver {
        let normalizedInstruction = instruction.lowercased()

        if normalizedInstruction.contains("arrive") || normalizedInstruction.contains("destination") {
            return .arrive
        }
        if normalizedInstruction.contains("u-turn") || normalizedInstruction.contains("u turn") {
            return .uTurn
        }
        if normalizedInstruction.contains("sharp left") {
            return .sharpLeft
        }
        if normalizedInstruction.contains("sharp right") {
            return .sharpRight
        }
        if normalizedInstruction.contains("slight left") || normalizedInstruction.contains("bear left") {
            return .slightLeft
        }
        if normalizedInstruction.contains("slight right") || normalizedInstruction.contains("bear right") {
            return .slightRight
        }
        if normalizedInstruction.contains("left") {
            return .left
        }
        if normalizedInstruction.contains("right") {
            return .right
        }
        if normalizedInstruction.contains("continue") || normalizedInstruction.contains("straight") || normalizedInstruction.contains("head") {
            return .straight
        }
        return .unknown
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
