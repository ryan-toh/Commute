import Foundation

/// Plans a MapKit cycling route, then may substitute a nearby curated cycling-path
/// segment or connected chain when MapKit can connect to both ends within the
/// configured journey-time trade-off.
@MainActor
final class CyclingPathRoutePlanningService: RoutePlanningService {
    private let mapKitService: any RoutePlanningService
    private let cyclingPathRepository: CyclingPathRepository

    init(
        mapKitService: any RoutePlanningService,
        cyclingPathRepository: CyclingPathRepository
    ) {
        self.mapKitService = mapKitService
        self.cyclingPathRepository = cyclingPathRepository
    }

    func planCyclingRoute(
        from origin: Location,
        to destination: Location
    ) async throws -> Route {
        try await planCyclingRouteWithDecisionTrace(from: origin, to: destination).route
    }

    func planCyclingRouteWithDecisionTrace(
        from origin: Location,
        to destination: Location
    ) async throws -> CyclingPathRoutePlanningResult {
        let directRoute: Route
        do {
            directRoute = try await mapKitService.planCyclingRoute(from: origin, to: destination)
        } catch RoutePlanningError.noRouteFound {
            guard let fallbackRoute = try await routeEndingNearDestination(
                from: origin,
                to: destination
            ) else {
                throw RoutePlanningError.noRouteFound
            }

            return CyclingPathRoutePlanningResult(
                route: fallbackRoute,
                trace: CyclingPathRouteDecisionTrace(
                    nearbySegmentCount: 0,
                    segmentTraversalCount: 0,
                    graphAnchorCount: 0,
                    graphAnchorPairCount: 0,
                    graphChainCount: 0,
                    candidateDecisions: [],
                    selectedCandidateID: nil
                )
            )
        }
        guard cyclingPathRepository.isPrepared else {
            return CyclingPathRoutePlanningResult(
                route: directRoute,
                trace: CyclingPathRouteDecisionTrace(
                    nearbySegmentCount: 0,
                    segmentTraversalCount: 0,
                    graphAnchorCount: 0,
                    graphAnchorPairCount: 0,
                    graphChainCount: 0,
                    candidateDecisions: [],
                    selectedCandidateID: nil
                )
            )
        }

        let candidates = candidateSegments(near: directRoute.coordinates)
        if Preferences.RoutePlanning.forceAllNearbyCyclingPathsForDevelopment,
           !candidates.isEmpty {
            return CyclingPathRoutePlanningResult(
                route: try await route(
                from: origin,
                throughAll: orderedCyclingPaths(candidates, along: directRoute.coordinates),
                to: destination
                ),
                trace: CyclingPathRouteDecisionTrace(
                    nearbySegmentCount: candidates.count,
                    segmentTraversalCount: 0,
                    graphAnchorCount: 0,
                    graphAnchorPairCount: 0,
                    graphChainCount: 0,
                    candidateDecisions: [],
                    selectedCandidateID: nil
                )
            )
        }

        let segmentTraversals = candidates
            .flatMap { candidateTraversals(from: $0, along: directRoute.coordinates) }
        let graphTraversalResult = graphTraversals(along: directRoute.coordinates)
        let traversals = (segmentTraversals + graphTraversalResult.traversals)
            .filter { $0.lengthMeters >= Preferences.RoutePlanning.minimumPreferredCyclingPathDistanceMeters }
            .sorted { $0.lengthMeters > $1.lengthMeters }
            .prefix(Preferences.RoutePlanning.maximumCyclingPathCandidates)

        var preferredRoute: Route?
        var preferredCandidateID: String?
        var preferredScore: Double?
        var candidateDecisions: [CyclingPathRouteCandidateDecision] = []

        for traversal in traversals {
            let candidateRoute: Route
            do {
                candidateRoute = try await route(
                    from: origin,
                    through: traversal.coordinates,
                    enteringAt: traversal.entry,
                    exitingAt: traversal.exit,
                    to: destination
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // An interior cycling-path point may not be routable by MapKit.
                // Ignore that traversal and retain the direct MapKit route.
                candidateDecisions.append(
                    CyclingPathRouteCandidateDecision(
                        id: traversal.id,
                        source: traversal.source,
                        cyclingPathDistanceMeters: traversal.lengthMeters,
                        outcome: .connectorRouteUnavailable
                    )
                )
                continue
            }
            guard isWithinAllowedPenalty(candidateRoute, comparedTo: directRoute) else {
                candidateDecisions.append(
                    CyclingPathRouteCandidateDecision(
                        id: traversal.id,
                        source: traversal.source,
                        cyclingPathDistanceMeters: traversal.lengthMeters,
                        outcome: .exceededTimePenalty(
                            addedTime: candidateRoute.expectedTravelTime - directRoute.expectedTravelTime
                        )
                    )
                )
                continue
            }
            let score = utility(
                for: candidateRoute,
                preferredDistanceMeters: traversal.lengthMeters,
                comparedTo: directRoute
            )
            guard score > 0 else {
                candidateDecisions.append(
                    CyclingPathRouteCandidateDecision(
                        id: traversal.id,
                        source: traversal.source,
                        cyclingPathDistanceMeters: traversal.lengthMeters,
                        outcome: .noNetBenefit(score: score)
                    )
                )
                continue
            }

            if preferredScore.map({ score > $0 }) ?? true {
                preferredRoute = candidateRoute
                preferredCandidateID = traversal.id
                preferredScore = score
            }

            candidateDecisions.append(
                CyclingPathRouteCandidateDecision(
                    id: traversal.id,
                    source: traversal.source,
                    cyclingPathDistanceMeters: traversal.lengthMeters,
                    outcome: .viable(score: score)
                )
            )
        }

        return CyclingPathRoutePlanningResult(
            route: preferredRoute ?? directRoute,
            trace: CyclingPathRouteDecisionTrace(
                nearbySegmentCount: candidates.count,
                segmentTraversalCount: segmentTraversals.count,
                graphAnchorCount: graphTraversalResult.anchorCount,
                graphAnchorPairCount: graphTraversalResult.anchorPairCount,
                graphChainCount: graphTraversalResult.chainCount,
                candidateDecisions: candidateDecisions,
                selectedCandidateID: preferredCandidateID
            )
        )
    }

    private func candidateSegments(near routeCoordinates: [LocationCoordinate]) -> [CyclingPathSegment] {
        let segmentsByID = routeCoordinates.reduce(into: [String: CyclingPathSegment]()) { result, coordinate in
            for segment in cyclingPathRepository.candidateSegments(
                near: coordinate,
                within: Preferences.RoutePlanning.cyclingPathSearchRadiusMeters
            ) {
                result[segment.id] = segment
            }
        }

        let nearbySegments = segmentsByID.values
            .filter { $0.coordinates.count >= 2 }
            .filter { segment in
                segment.coordinates.contains { segmentCoordinate in
                    routeCoordinates.contains { routeCoordinate in
                        distance(between: segmentCoordinate, and: routeCoordinate) <= Preferences.RoutePlanning.cyclingPathSearchRadiusMeters
                    }
                }
            }
            .sorted {
                nearestCoordinateIndex(to: $0.coordinates[0], in: routeCoordinates) <
                    nearestCoordinateIndex(to: $1.coordinates[0], in: routeCoordinates)
            }

        if Preferences.RoutePlanning.forceAllNearbyCyclingPathsForDevelopment {
            return nearbySegments
        }

        return Array(nearbySegments.prefix(Preferences.RoutePlanning.maximumCyclingPathCandidates))
    }

    private func routeEndingNearDestination(
        from origin: Location,
        to destination: Location
    ) async throws -> Route? {
        guard cyclingPathRepository.isPrepared else { return nil }

        let fallbackTargets = cyclingPathRepository.candidateSegments(
            near: destination.coordinate,
            within: Preferences.RoutePlanning.destinationFallbackSearchRadiusMeters
        )
        .compactMap { segment in
            nearestPoint(on: segment.coordinates, to: destination.coordinate).map {
                CyclingPathFallbackCandidate(
                    segmentCoordinates: segment.coordinates,
                    target: $0
                )
            }
        }
        .filter {
            $0.target.remainingDistanceMeters <= Preferences.RoutePlanning.destinationFallbackSearchRadiusMeters
        }
        .sorted { $0.target.remainingDistanceMeters < $1.target.remainingDistanceMeters }
        .prefix(Preferences.RoutePlanning.maximumDestinationFallbackTargets)

        for candidate in fallbackTargets {
            do {
                let fallbackLocation = location(
                    at: candidate.target.coordinate,
                    named: Preferences.RoutePlanning.nearbyCyclingPathDestinationName
                )
                let route = try await mapKitService.planCyclingRoute(
                    from: origin,
                    to: fallbackLocation
                )
                return Route(
                    id: route.id,
                    coordinates: route.coordinates,
                    steps: route.steps,
                    distanceMeters: route.distanceMeters,
                    expectedTravelTime: route.expectedTravelTime,
                    transportMode: route.transportMode,
                    arrival: .indirect(
                        remainingDistanceMeters: candidate.target.remainingDistanceMeters
                    )
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // MapKit often cannot route directly to an off-road PCN point.
                // Try its segment endpoints, then append the matching PCN portion.
            }

            for cyclingPath in cyclingPathApproaches(to: candidate) {
                guard let entry = cyclingPath.first else { continue }
                do {
                    let approach = try await mapKitService.planCyclingRoute(
                        from: origin,
                        to: location(at: entry, named: Preferences.RoutePlanning.nearbyCyclingPathDestinationName)
                    )
                    return route(
                        byAppending: cyclingPath,
                        to: approach,
                        remainingDistanceMeters: candidate.target.remainingDistanceMeters
                    )
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    continue
                }
            }
        }

        return nil
    }

    private func orderedCyclingPaths(
        _ segments: [CyclingPathSegment],
        along routeCoordinates: [LocationCoordinate]
    ) -> [[LocationCoordinate]] {
        segments.map { segment in
            let firstIndex = nearestCoordinateIndex(to: segment.coordinates[0], in: routeCoordinates)
            let lastIndex = nearestCoordinateIndex(
                to: segment.coordinates[segment.coordinates.count - 1],
                in: routeCoordinates
            )
            return firstIndex <= lastIndex ? segment.coordinates : Array(segment.coordinates.reversed())
        }
    }

    private func candidateTraversals(
        from segment: CyclingPathSegment,
        along baselineCoordinates: [LocationCoordinate]
    ) -> [CyclingPathTraversal] {
        [
            endpointTraversal(
                id: "segment-\(segment.id)-forward",
                from: segment.coordinates,
                along: baselineCoordinates
            ),
            endpointTraversal(
                id: "segment-\(segment.id)-reverse",
                from: Array(segment.coordinates.reversed()),
                along: baselineCoordinates
            )
        ]
        .compactMap { $0 }
    }

    private func graphTraversals(along baselineCoordinates: [LocationCoordinate]) -> GraphTraversalResult {
        var anchorsByNodeID: [Int: BaselineProjection] = [:]

        for baselineCoordinate in baselineCoordinates {
            for nodeID in cyclingPathRepository.graphNodeIDs(
                near: baselineCoordinate,
                within: Preferences.RoutePlanning.cyclingPathSearchRadiusMeters
            ) {
                guard let nodeCoordinate = cyclingPathRepository.graphNodeCoordinate(for: nodeID),
                      let projection = project(nodeCoordinate, onto: baselineCoordinates),
                      projection.distanceMeters <= Preferences.RoutePlanning.cyclingPathSearchRadiusMeters else {
                    continue
                }

                if projection.distanceMeters < (anchorsByNodeID[nodeID]?.distanceMeters ?? .infinity) {
                    anchorsByNodeID[nodeID] = projection
                }
            }
        }

        let anchors = anchorsByNodeID.map { GraphAnchor(nodeID: $0.key, projection: $0.value) }
        let anchorsByComponentID = Dictionary(grouping: anchors) { anchor in
            cyclingPathRepository.graphComponentID(for: anchor.nodeID)
        }
        let pairs = anchorsByComponentID.values.flatMap { componentAnchors in
            componentAnchors.flatMap { entry in
                componentAnchors.compactMap { exit -> GraphAnchorPair? in
                    guard exit.projection.progressMeters >= entry.projection.progressMeters + Preferences.RoutePlanning.minimumCyclingPathForwardProgressMeters else {
                        return nil
                    }
                    return GraphAnchorPair(entry: entry, exit: exit)
                }
            }
        }
        .sorted { first, second in
            first.forwardProgressMeters > second.forwardProgressMeters
        }
        .prefix(Preferences.RoutePlanning.maximumCyclingPathGraphAnchorPairs)

        let traversals: [CyclingPathTraversal] = pairs.compactMap { pair -> CyclingPathTraversal? in
            guard let chain = cyclingPathRepository.shortestCyclingPathChain(
                from: pair.entry.nodeID,
                to: pair.exit.nodeID
            ), chain.lengthMeters >= Preferences.RoutePlanning.minimumPreferredCyclingPathDistanceMeters,
                  let entry = chain.coordinates.first,
                  let exit = chain.coordinates.last else {
                return nil
            }

            return CyclingPathTraversal(
                id: "graph-\(pair.entry.nodeID)-\(pair.exit.nodeID)",
                source: .connectedChain,
                coordinates: chain.coordinates,
                entry: entry,
                exit: exit,
                lengthMeters: chain.lengthMeters
            )
        }

        return GraphTraversalResult(
            traversals: traversals,
            anchorCount: anchors.count,
            anchorPairCount: pairs.count,
            chainCount: traversals.count
        )
    }

    private func endpointTraversal(
        id: String,
        from coordinates: [LocationCoordinate],
        along baselineCoordinates: [LocationCoordinate]
    ) -> CyclingPathTraversal? {
        guard let entry = coordinates.first,
              let exit = coordinates.last,
              let entryProjection = project(entry, onto: baselineCoordinates),
              let exitProjection = project(exit, onto: baselineCoordinates),
              entryProjection.distanceMeters <= Preferences.RoutePlanning.cyclingPathSearchRadiusMeters,
              exitProjection.distanceMeters <= Preferences.RoutePlanning.cyclingPathSearchRadiusMeters,
              exitProjection.progressMeters >= entryProjection.progressMeters + Preferences.RoutePlanning.minimumCyclingPathForwardProgressMeters else {
            return nil
        }

        return CyclingPathTraversal(
            id: id,
            source: .singleSegment,
            coordinates: coordinates,
            entry: entry,
            exit: exit,
            lengthMeters: length(of: coordinates)
        )
    }

    private func nearestPoint(
        on coordinates: [LocationCoordinate],
        to destination: LocationCoordinate
    ) -> CyclingPathFallbackTarget? {
        guard coordinates.count >= 2 else { return nil }

        var closestTarget: CyclingPathFallbackTarget?
        for precedingCoordinateIndex in coordinates.indices.dropLast() {
            let start = coordinates[precedingCoordinateIndex]
            let end = coordinates[precedingCoordinateIndex + 1]
            let latitude = (start.latitude + end.latitude + destination.latitude) / 3
            let longitudeScale = Preferences.CyclingPaths.metersPerLongitudeDegree(at: latitude)
            let segmentX = (end.longitude - start.longitude) * longitudeScale
            let segmentY = (end.latitude - start.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
            let segmentLengthSquared = segmentX * segmentX + segmentY * segmentY
            guard segmentLengthSquared > 0 else { continue }

            let pointX = (destination.longitude - start.longitude) * longitudeScale
            let pointY = (destination.latitude - start.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
            let fraction = min(max((pointX * segmentX + pointY * segmentY) / segmentLengthSquared, 0), 1)
            let coordinate = LocationCoordinate(
                latitude: start.latitude + (end.latitude - start.latitude) * fraction,
                longitude: start.longitude + (end.longitude - start.longitude) * fraction
            )
            let target = CyclingPathFallbackTarget(
                coordinate: coordinate,
                remainingDistanceMeters: distance(between: coordinate, and: destination),
                precedingCoordinateIndex: precedingCoordinateIndex
            )
            if closestTarget.map({ target.remainingDistanceMeters < $0.remainingDistanceMeters }) ?? true {
                closestTarget = target
            }
        }

        return closestTarget
    }

    private func cyclingPathApproaches(
        to candidate: CyclingPathFallbackCandidate
    ) -> [[LocationCoordinate]] {
        let coordinates = candidate.segmentCoordinates
        let target = candidate.target
        let startPath = append(
            target.coordinate,
            to: Array(coordinates[...target.precedingCoordinateIndex])
        )
        let endPath = append(
            target.coordinate,
            to: Array(coordinates[(target.precedingCoordinateIndex + 1)...].reversed())
        )
        return [startPath, endPath]
            .filter { $0.count >= 2 }
    }

    private func append(
        _ coordinate: LocationCoordinate,
        to coordinates: [LocationCoordinate]
    ) -> [LocationCoordinate] {
        guard coordinates.last != coordinate else { return coordinates }
        return coordinates + [coordinate]
    }

    private func route(
        byAppending cyclingPath: [LocationCoordinate],
        to approach: Route,
        remainingDistanceMeters: Double
    ) -> Route {
        let coordinates = joinedCoordinates(approach.coordinates, cyclingPath)
        let cyclingPathLength = length(of: cyclingPath)
        let arrivalCoordinate = cyclingPath.last ?? approach.coordinates.last ?? cyclingPath[0]
        let approachSteps = approach.steps.filter { $0.maneuver != .arrive }
        let cyclingPathStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.cyclingPathInstruction,
            maneuver: .straight,
            distanceMeters: cyclingPathLength,
            coordinate: arrivalCoordinate,
            routeCoordinateIndex: nearestCoordinateIndex(to: arrivalCoordinate, in: coordinates),
            transportMode: .cycling,
            source: .curatedPath
        )
        let arrivalStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.nearbyDestinationArrivalInstruction,
            maneuver: .arrive,
            distanceMeters: 0,
            coordinate: arrivalCoordinate,
            routeCoordinateIndex: nearestCoordinateIndex(to: arrivalCoordinate, in: coordinates),
            transportMode: .cycling,
            source: .curatedPath
        )

        return Route(
            id: UUID(),
            coordinates: coordinates,
            steps: remappedSteps(approachSteps, in: coordinates) + [cyclingPathStep, arrivalStep],
            distanceMeters: approach.distanceMeters + cyclingPathLength,
            expectedTravelTime: approach.expectedTravelTime + cyclingPathTravelTime(for: cyclingPath),
            transportMode: .cycling,
            arrival: .indirect(remainingDistanceMeters: remainingDistanceMeters)
        )
    }

    private func route(
        from origin: Location,
        through cyclingPath: [LocationCoordinate],
        enteringAt entry: LocationCoordinate,
        exitingAt exit: LocationCoordinate,
        to destination: Location
    ) async throws -> Route {
        async let approachRoute = mapKitService.planCyclingRoute(
            from: origin,
            to: location(at: entry, named: "Cycling path entry")
        )
        async let departureRoute = mapKitService.planCyclingRoute(
            from: location(at: exit, named: "Cycling path exit"),
            to: destination
        )

        let approach = try await approachRoute
        let departure = try await departureRoute
        let coordinates = joinedCoordinates(
            approach.coordinates,
            cyclingPath,
            departure.coordinates
        )
        let approachSteps = approach.steps.filter { $0.maneuver != .arrive }
        let curatedStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.cyclingPathInstruction,
            maneuver: .straight,
            distanceMeters: length(of: cyclingPath),
            coordinate: cyclingPath.last ?? exit,
            routeCoordinateIndex: nearestCoordinateIndex(to: cyclingPath.last ?? exit, in: coordinates),
            transportMode: .cycling,
            source: .curatedPath
        )

        return Route(
            id: UUID(),
            coordinates: coordinates,
            steps: remappedSteps(approachSteps, in: coordinates) + [curatedStep] + remappedSteps(departure.steps, in: coordinates),
            distanceMeters: approach.distanceMeters + length(of: cyclingPath) + departure.distanceMeters,
            expectedTravelTime: approach.expectedTravelTime
                + cyclingPathTravelTime(for: cyclingPath)
                + departure.expectedTravelTime,
            transportMode: .cycling
        )
    }

    private func route(
        from origin: Location,
        throughAll cyclingPaths: [[LocationCoordinate]],
        to destination: Location
    ) async throws -> Route {
        var currentLocation = origin
        var coordinates: [LocationCoordinate] = []
        var steps: [RouteStep] = []
        var totalDistance = 0.0
        var totalTravelTime: TimeInterval = 0

        for cyclingPath in cyclingPaths {
            guard let entry = cyclingPath.first, let exit = cyclingPath.last else { continue }
            let approach = try await mapKitService.planCyclingRoute(
                from: currentLocation,
                to: location(at: entry, named: "Cycling path entry")
            )
            coordinates = joinedCoordinates(coordinates, approach.coordinates, cyclingPath)
            steps += approach.steps.filter { $0.maneuver != .arrive }
            steps.append(
                RouteStep(
                    id: UUID(),
                    instruction: Preferences.RoutePlanning.cyclingPathInstruction,
                    maneuver: .straight,
                    distanceMeters: length(of: cyclingPath),
                    coordinate: exit,
                    routeCoordinateIndex: 0,
                    transportMode: .cycling,
                    source: .curatedPath
                )
            )
            totalDistance += approach.distanceMeters + length(of: cyclingPath)
            totalTravelTime += approach.expectedTravelTime + cyclingPathTravelTime(for: cyclingPath)
            currentLocation = location(at: exit, named: "Cycling path exit")
        }

        let departure = try await mapKitService.planCyclingRoute(from: currentLocation, to: destination)
        coordinates = joinedCoordinates(coordinates, departure.coordinates)
        steps += departure.steps
        totalDistance += departure.distanceMeters
        totalTravelTime += departure.expectedTravelTime

        return Route(
            id: UUID(),
            coordinates: coordinates,
            steps: remappedSteps(steps, in: coordinates),
            distanceMeters: totalDistance,
            expectedTravelTime: totalTravelTime,
            transportMode: .cycling
        )
    }

    private func isWithinAllowedPenalty(_ route: Route, comparedTo directRoute: Route) -> Bool {
        route.expectedTravelTime <= directRoute.expectedTravelTime + Preferences.RoutePlanning.maximumTravelTimePenalty
    }

    private func utility(
        for route: Route,
        preferredDistanceMeters: Double,
        comparedTo directRoute: Route
    ) -> Double {
        // Prefer more cycling-path distance, while charging only for travel added
        // beyond the direct route. The hard time cap remains a separate safeguard.
        let addedTime = max(0, route.expectedTravelTime - directRoute.expectedTravelTime)
        let addedDistance = max(0, route.distanceMeters - directRoute.distanceMeters)
        return preferredDistanceMeters
            - addedTime * Preferences.RoutePlanning.cyclingPathAddedTimePenaltyPerSecond
            - addedDistance * Preferences.RoutePlanning.cyclingPathAddedDistancePenalty
    }

    private func cyclingPathTravelTime(for coordinates: [LocationCoordinate]) -> TimeInterval {
        length(of: coordinates) / Preferences.RoutePlanning.assumedCyclingPathSpeedMetersPerSecond
    }

    private func remappedSteps(_ steps: [RouteStep], in coordinates: [LocationCoordinate]) -> [RouteStep] {
        steps.map { step in
            RouteStep(
                id: step.id,
                instruction: step.instruction,
                maneuver: step.maneuver,
                distanceMeters: step.distanceMeters,
                coordinate: step.coordinate,
                routeCoordinateIndex: nearestCoordinateIndex(to: step.coordinate, in: coordinates),
                transportMode: step.transportMode,
                source: step.source
            )
        }
    }

    private func joinedCoordinates(_ coordinateGroups: [LocationCoordinate]...) -> [LocationCoordinate] {
        coordinateGroups.reduce(into: []) { result, coordinates in
            for coordinate in coordinates where result.last != coordinate {
                result.append(coordinate)
            }
        }
    }

    private func location(at coordinate: LocationCoordinate, named name: String) -> Location {
        Location(
            id: UUID(),
            coordinate: coordinate,
            address: nil,
            name: name,
            source: .unknown,
            capturedAt: .now
        )
    }

    private func nearestCoordinateIndex(to target: LocationCoordinate, in coordinates: [LocationCoordinate]) -> Int {
        coordinates.indices.min { first, second in
            squaredDistance(between: coordinates[first], and: target) < squaredDistance(between: coordinates[second], and: target)
        } ?? 0
    }

    private func project(
        _ coordinate: LocationCoordinate,
        onto baselineCoordinates: [LocationCoordinate]
    ) -> BaselineProjection? {
        guard baselineCoordinates.count >= 2 else { return nil }

        var closestProjection: BaselineProjection?
        var distanceAlongBaseline = 0.0

        for (start, end) in zip(baselineCoordinates, baselineCoordinates.dropFirst()) {
            let segmentLength = distance(between: start, and: end)
            guard segmentLength > 0 else { continue }

            let latitude = (start.latitude + end.latitude + coordinate.latitude) / 3
            let longitudeScale = Preferences.CyclingPaths.metersPerLongitudeDegree(at: latitude)
            let segmentX = (end.longitude - start.longitude) * longitudeScale
            let segmentY = (end.latitude - start.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
            let pointX = (coordinate.longitude - start.longitude) * longitudeScale
            let pointY = (coordinate.latitude - start.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
            let unboundedFraction = (pointX * segmentX + pointY * segmentY) / (segmentLength * segmentLength)
            let fraction = min(max(unboundedFraction, 0), 1)
            let closestX = segmentX * fraction
            let closestY = segmentY * fraction
            let distanceToSegment = hypot(pointX - closestX, pointY - closestY)
            let projection = BaselineProjection(
                progressMeters: distanceAlongBaseline + segmentLength * fraction,
                distanceMeters: distanceToSegment
            )

            if closestProjection.map({ distanceToSegment < $0.distanceMeters }) ?? true {
                closestProjection = projection
            }

            distanceAlongBaseline += segmentLength
        }

        return closestProjection
    }

    private func length(of coordinates: [LocationCoordinate]) -> Double {
        zip(coordinates, coordinates.dropFirst())
            .reduce(0) { $0 + distance(between: $1.0, and: $1.1) }
    }

    private func distance(between first: LocationCoordinate, and second: LocationCoordinate) -> Double {
        let latitudeDelta = (second.latitude - first.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
        let longitudeDelta = (second.longitude - first.longitude) * Preferences.CyclingPaths.metersPerLongitudeDegree(at: (first.latitude + second.latitude) / 2)
        return hypot(latitudeDelta, longitudeDelta)
    }

    private func squaredDistance(between first: LocationCoordinate, and second: LocationCoordinate) -> Double {
        let distance = distance(between: first, and: second)
        return distance * distance
    }
}

private struct CyclingPathTraversal {
    let id: String
    let source: CyclingPathRouteCandidateSource
    let coordinates: [LocationCoordinate]
    let entry: LocationCoordinate
    let exit: LocationCoordinate
    let lengthMeters: Double
}

private struct CyclingPathFallbackTarget {
    let coordinate: LocationCoordinate
    let remainingDistanceMeters: Double
    let precedingCoordinateIndex: Int
}

private struct CyclingPathFallbackCandidate {
    let segmentCoordinates: [LocationCoordinate]
    let target: CyclingPathFallbackTarget
}

private struct GraphTraversalResult {
    let traversals: [CyclingPathTraversal]
    let anchorCount: Int
    let anchorPairCount: Int
    let chainCount: Int
}

private struct BaselineProjection {
    let progressMeters: Double
    let distanceMeters: Double
}

private struct GraphAnchor {
    let nodeID: Int
    let projection: BaselineProjection
}

private struct GraphAnchorPair {
    let entry: GraphAnchor
    let exit: GraphAnchor

    var forwardProgressMeters: Double {
        exit.projection.progressMeters - entry.projection.progressMeters
    }
}

struct CyclingPathRoutePlanningResult {
    let route: Route
    let trace: CyclingPathRouteDecisionTrace
}

struct CyclingPathRouteDecisionTrace {
    let nearbySegmentCount: Int
    let segmentTraversalCount: Int
    let graphAnchorCount: Int
    let graphAnchorPairCount: Int
    let graphChainCount: Int
    let candidateDecisions: [CyclingPathRouteCandidateDecision]
    let selectedCandidateID: String?
}

struct CyclingPathRouteCandidateDecision: Identifiable {
    let id: String
    let source: CyclingPathRouteCandidateSource
    let cyclingPathDistanceMeters: Double
    let outcome: CyclingPathRouteCandidateOutcome
}

enum CyclingPathRouteCandidateSource {
    case singleSegment
    case connectedChain
}

enum CyclingPathRouteCandidateOutcome {
    case connectorRouteUnavailable
    case exceededTimePenalty(addedTime: TimeInterval)
    case noNetBenefit(score: Double)
    case viable(score: Double)
}
