import Foundation

struct CyclingPathRouteAssembler {
    private let geometry = CyclingPathGeometry()

    func assembleRoute(from candidate: EvaluatedCyclingPathCandidate) -> Route {
        let approachRoute = candidate.bridges.approachRoute
        let departureRoute = candidate.bridges.departureRoute
        let cyclingPathCoordinates = candidate.excursion.networkRoute.coordinates
        let routeCoordinates = joinedCoordinates(
            approachRoute.coordinates,
            cyclingPathCoordinates,
            departureRoute.coordinates
        )

        let approachStepsWithoutArrival = approachRoute.steps.filter {
            $0.maneuver != .arrive
        }
        let cyclingPathExitCoordinate = candidate.excursion.exitCoordinate
        let cyclingPathStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.cyclingPathInstruction,
            maneuver: .straight,
            distanceMeters: candidate.excursion.networkRoute.totalDistanceMeters,
            coordinate: cyclingPathExitCoordinate,
            routeCoordinateIndex: nearestCoordinateIndex(
                to: cyclingPathExitCoordinate,
                in: routeCoordinates
            ),
            transportMode: .cycling,
            source: .curatedPath
        )

        let combinedSteps = remappedSteps(
            approachStepsWithoutArrival + [cyclingPathStep] + departureRoute.steps,
            in: routeCoordinates
        )
        return Route(
            id: UUID(),
            coordinates: routeCoordinates,
            steps: combinedSteps,
            distanceMeters: candidate.totalDistanceMeters,
            expectedTravelTime: candidate.totalTravelTime,
            transportMode: .cycling,
            arrival: departureRoute.arrival
        )
    }

    private func joinedCoordinates(
        _ coordinateGroups: [LocationCoordinate]...
    ) -> [LocationCoordinate] {
        var joinedCoordinates: [LocationCoordinate] = []
        for coordinateGroup in coordinateGroups {
            for coordinate in coordinateGroup where joinedCoordinates.last != coordinate {
                joinedCoordinates.append(coordinate)
            }
        }
        return joinedCoordinates
    }

    private func remappedSteps(
        _ steps: [RouteStep],
        in routeCoordinates: [LocationCoordinate]
    ) -> [RouteStep] {
        steps.map { step in
            RouteStep(
                id: step.id,
                instruction: step.instruction,
                maneuver: step.maneuver,
                distanceMeters: step.distanceMeters,
                coordinate: step.coordinate,
                routeCoordinateIndex: nearestCoordinateIndex(
                    to: step.coordinate,
                    in: routeCoordinates
                ),
                transportMode: step.transportMode,
                source: step.source
            )
        }
    }

    private func nearestCoordinateIndex(
        to targetCoordinate: LocationCoordinate,
        in routeCoordinates: [LocationCoordinate]
    ) -> Int {
        routeCoordinates.indices.min { firstIndex, secondIndex in
            geometry.distance(from: routeCoordinates[firstIndex], to: targetCoordinate)
                < geometry.distance(from: routeCoordinates[secondIndex], to: targetCoordinate)
        } ?? 0
    }
}
