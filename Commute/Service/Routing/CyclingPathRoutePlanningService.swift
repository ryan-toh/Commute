import Foundation

/// Plans a direct MapKit route and evaluates cycling-path excursions that may replace
/// part of that route without exceeding the configured travel-time allowance.
@MainActor
final class CyclingPathRoutePlanningService: RoutePlanningService {
    private let directRoutePlanningService: any RoutePlanningService
    private let cyclingPathRepository: CyclingPathRepository
    private let bridgePlanner: any CyclingPathBridgePlanning

    private let candidateExcursionSearch = CyclingPathCandidateExcursionSearch()
    private let candidateEvaluator = CyclingPathCandidateEvaluator()
    private let candidateRanker = CyclingPathCandidateRanker()
    private let routeAssembler = CyclingPathRouteAssembler()
    private let geometry = CyclingPathGeometry()

    init(
        mapKitService: any RoutePlanningService,
        cyclingPathRepository: CyclingPathRepository,
        bridgePlanner: (any CyclingPathBridgePlanning)? = nil
    ) {
        self.directRoutePlanningService = mapKitService
        self.cyclingPathRepository = cyclingPathRepository
        self.bridgePlanner = bridgePlanner
            ?? RoutePlanningCyclingPathBridgePlanner(routePlanningService: mapKitService)
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
            directRoute = try await directRoutePlanningService.planCyclingRoute(
                from: origin,
                to: destination
            )
        } catch RoutePlanningError.noRouteFound {
            guard let fallbackRoute = try await routeEndingNearDestination(
                from: origin,
                to: destination
            ) else {
                throw RoutePlanningError.noRouteFound
            }
            return CyclingPathRoutePlanningResult(route: fallbackRoute, trace: .empty)
        }

        guard cyclingPathRepository.isPrepared,
              !cyclingPathRepository.network.edgesByID.isEmpty else {
            return CyclingPathRoutePlanningResult(route: directRoute, trace: .empty)
        }

        let excursionSearch = candidateExcursionSearch.findExcursions(
            near: directRoute,
            destinationCoordinate: destination.coordinate,
            in: cyclingPathRepository.network,
            configuration: makeCandidateExcursionSearchConfiguration()
        )
        let candidateEvaluation = try await evaluateCandidates(
            excursionSearch.excursions,
            from: origin,
            to: destination,
            comparedTo: directRoute
        )
        let preferredCandidate = candidateRanker.preferredCandidate(
            from: candidateEvaluation.acceptedCandidates
        )
        let selectedRoute: Route
        if let preferredCandidate {
            selectedRoute = routeAssembler.assembleRoute(from: preferredCandidate)
        } else {
            selectedRoute = directRoute
        }

        return CyclingPathRoutePlanningResult(
            route: selectedRoute,
            trace: CyclingPathRouteDecisionTrace(
                excursionAnchorCount: excursionSearch.generatedAnchorCount,
                compatibleAnchorPairCount: excursionSearch.compatibleAnchorPairCount,
                candidateExcursionCount: excursionSearch.excursions.count,
                viableCandidateCount: candidateEvaluation.acceptedCandidates.count,
                candidateDecisions: candidateEvaluation.decisions,
                selectedCandidateID: preferredCandidate?.excursion.identifier
            )
        )
    }

    private func makeCandidateExcursionSearchConfiguration()
        -> CyclingPathCandidateExcursionSearchConfiguration {
        CyclingPathCandidateExcursionSearchConfiguration(
            maximumAnchorDistanceFromBaselineMeters: Preferences.RoutePlanning.cyclingPathSearchRadiusMeters,
            maximumProjectionsPerBaselineCoordinate: Preferences.RoutePlanning.maximumCyclingPathProjectionsPerBaselineCoordinate,
            maximumAnchorCount: Preferences.RoutePlanning.maximumCandidateExcursionAnchors,
            minimumForwardProgressMeters: Preferences.RoutePlanning.minimumCyclingPathForwardProgressMeters,
            maximumAnchorPairCount: Preferences.RoutePlanning.maximumCandidateExcursionAnchorPairs,
            maximumNetworkRouteDistanceMeters: Preferences.RoutePlanning.maximumCandidateExcursionNetworkDistanceMeters,
            minimumCyclingPathDistanceMeters: Preferences.RoutePlanning.minimumCandidateExcursionCyclingPathDistanceMeters,
            minimumDestinationProgressMeters: Preferences.RoutePlanning.minimumDestinationProgressMeters,
            maximumNetworkDistanceToBaselineProgressRatio: Preferences.RoutePlanning.maximumExcursionDistanceToBaselineProgressRatio,
            maximumReturnedExcursionCount: Preferences.RoutePlanning.maximumCandidateExcursions
        )
    }

    private func evaluateCandidates(
        _ excursions: [CyclingPathExcursion],
        from origin: Location,
        to destination: Location,
        comparedTo directRoute: Route
    ) async throws -> CandidateEvaluationResult {
        var acceptedCandidates: [EvaluatedCyclingPathCandidate] = []
        var decisions: [CyclingPathRouteCandidateDecision] = []

        for excursion in excursions {
            let bridges: CyclingPathBridges
            do {
                bridges = try await bridgePlanner.planBridges(
                    from: origin,
                    through: excursion,
                    to: destination
                )
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                decisions.append(decision(for: excursion, outcome: .connectorRouteUnavailable))
                continue
            }

            let evaluation = candidateEvaluator.evaluate(
                excursion: excursion,
                bridges: bridges,
                directRoute: directRoute,
                assumedCyclingSpeedMetersPerSecond: Preferences.RoutePlanning.assumedCyclingPathSpeedMetersPerSecond,
                maximumAddedTravelTimePercentage: Preferences.RoutePlanning.maximumAddedTravelTimePercentage
            )
            switch evaluation {
            case let .accepted(candidate):
                acceptedCandidates.append(candidate)
                decisions.append(
                    decision(
                        for: excursion,
                        outcome: .viable
                    )
                )
            case .rejectedForInvalidConfiguration:
                decisions.append(
                    decision(for: excursion, outcome: .invalidConfiguration)
                )
            case let .rejectedForTravelTime(addedTravelTime):
                decisions.append(
                    decision(
                        for: excursion,
                        outcome: .exceededTimePenalty(addedTime: addedTravelTime)
                    )
                )
            }
        }

        return CandidateEvaluationResult(
            acceptedCandidates: acceptedCandidates,
            decisions: decisions
        )
    }

    private func decision(
        for excursion: CyclingPathExcursion,
        outcome: CyclingPathRouteCandidateOutcome
    ) -> CyclingPathRouteCandidateDecision {
        CyclingPathRouteCandidateDecision(
            id: excursion.identifier,
            cyclingPathDistanceMeters: excursion.networkRoute.cyclingPathDistanceMeters,
            outcome: outcome
        )
    }

    private func routeEndingNearDestination(
        from origin: Location,
        to destination: Location
    ) async throws -> Route? {
        guard cyclingPathRepository.isPrepared else { return nil }

        let fallbackCandidates = cyclingPathRepository.candidateSegments(
            near: destination.coordinate,
            within: Preferences.RoutePlanning.destinationFallbackSearchRadiusMeters
        )
        .compactMap { segment -> CyclingPathFallbackCandidate? in
            guard let target = nearestPoint(on: segment.coordinates, to: destination.coordinate) else {
                return nil
            }
            return CyclingPathFallbackCandidate(
                segmentCoordinates: segment.coordinates,
                target: target
            )
        }
        .filter {
            $0.target.remainingDistanceMeters
                <= Preferences.RoutePlanning.destinationFallbackSearchRadiusMeters
        }
        .sorted { $0.target.remainingDistanceMeters < $1.target.remainingDistanceMeters }
        .prefix(Preferences.RoutePlanning.maximumDestinationFallbackTargets)

        for candidate in fallbackCandidates {
            if let directFallbackRoute = try await directFallbackRoute(
                from: origin,
                to: candidate
            ) {
                return directFallbackRoute
            }

            for cyclingPathApproach in cyclingPathApproaches(to: candidate) {
                guard let entryCoordinate = cyclingPathApproach.first else { continue }
                do {
                    let mapKitApproach = try await directRoutePlanningService.planCyclingRoute(
                        from: origin,
                        to: makeLocation(
                            at: entryCoordinate,
                            named: Preferences.RoutePlanning.nearbyCyclingPathDestinationName
                        )
                    )
                    return appendFallbackCyclingPath(
                        cyclingPathApproach,
                        to: mapKitApproach,
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

    private func directFallbackRoute(
        from origin: Location,
        to candidate: CyclingPathFallbackCandidate
    ) async throws -> Route? {
        do {
            let route = try await directRoutePlanningService.planCyclingRoute(
                from: origin,
                to: makeLocation(
                    at: candidate.target.coordinate,
                    named: Preferences.RoutePlanning.nearbyCyclingPathDestinationName
                )
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
            return nil
        }
    }

    private func nearestPoint(
        on coordinates: [LocationCoordinate],
        to destination: LocationCoordinate
    ) -> CyclingPathFallbackTarget? {
        guard coordinates.count >= 2 else { return nil }

        var closestTarget: CyclingPathFallbackTarget?
        for coordinateIndex in coordinates.indices.dropLast() {
            guard let projection = geometry.projection(
                of: destination,
                onto: coordinates[coordinateIndex],
                and: coordinates[coordinateIndex + 1]
            ) else {
                continue
            }
            let target = CyclingPathFallbackTarget(
                coordinate: projection.coordinate,
                remainingDistanceMeters: projection.distanceFromQueryMeters,
                precedingCoordinateIndex: coordinateIndex
            )
            if closestTarget.map({
                target.remainingDistanceMeters < $0.remainingDistanceMeters
            }) ?? true {
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
        let pathFromStart = appendingIfNeeded(
            target.coordinate,
            to: Array(coordinates[...target.precedingCoordinateIndex])
        )
        let pathFromEnd = appendingIfNeeded(
            target.coordinate,
            to: Array(coordinates[(target.precedingCoordinateIndex + 1)...].reversed())
        )
        return [pathFromStart, pathFromEnd].filter { $0.count >= 2 }
    }

    private func appendingIfNeeded(
        _ coordinate: LocationCoordinate,
        to coordinates: [LocationCoordinate]
    ) -> [LocationCoordinate] {
        guard coordinates.last != coordinate else { return coordinates }
        return coordinates + [coordinate]
    }

    private func appendFallbackCyclingPath(
        _ cyclingPathCoordinates: [LocationCoordinate],
        to approachRoute: Route,
        remainingDistanceMeters: Double
    ) -> Route {
        var routeCoordinates = approachRoute.coordinates
        for coordinate in cyclingPathCoordinates where routeCoordinates.last != coordinate {
            routeCoordinates.append(coordinate)
        }
        let cyclingPathDistanceMeters = geometry.length(of: cyclingPathCoordinates)
        let arrivalCoordinate = cyclingPathCoordinates.last
            ?? approachRoute.coordinates.last
            ?? cyclingPathCoordinates[0]
        let approachSteps = approachRoute.steps.filter { $0.maneuver != .arrive }
        let cyclingPathStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.cyclingPathInstruction,
            maneuver: .straight,
            distanceMeters: cyclingPathDistanceMeters,
            coordinate: arrivalCoordinate,
            routeCoordinateIndex: nearestCoordinateIndex(to: arrivalCoordinate, in: routeCoordinates),
            transportMode: .cycling,
            source: .curatedPath
        )
        let arrivalStep = RouteStep(
            id: UUID(),
            instruction: Preferences.RoutePlanning.nearbyDestinationArrivalInstruction,
            maneuver: .arrive,
            distanceMeters: 0,
            coordinate: arrivalCoordinate,
            routeCoordinateIndex: nearestCoordinateIndex(to: arrivalCoordinate, in: routeCoordinates),
            transportMode: .cycling,
            source: .curatedPath
        )
        let remappedApproachSteps = approachSteps.map { step in
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

        return Route(
            id: UUID(),
            coordinates: routeCoordinates,
            steps: remappedApproachSteps + [cyclingPathStep, arrivalStep],
            distanceMeters: approachRoute.distanceMeters + cyclingPathDistanceMeters,
            expectedTravelTime: approachRoute.expectedTravelTime
                + cyclingPathDistanceMeters
                    / Preferences.RoutePlanning.assumedCyclingPathSpeedMetersPerSecond,
            transportMode: .cycling,
            arrival: .indirect(remainingDistanceMeters: remainingDistanceMeters)
        )
    }

    private func nearestCoordinateIndex(
        to targetCoordinate: LocationCoordinate,
        in coordinates: [LocationCoordinate]
    ) -> Int {
        coordinates.indices.min { firstIndex, secondIndex in
            geometry.distance(from: coordinates[firstIndex], to: targetCoordinate)
                < geometry.distance(from: coordinates[secondIndex], to: targetCoordinate)
        } ?? 0
    }

    private func makeLocation(
        at coordinate: LocationCoordinate,
        named name: String
    ) -> Location {
        Location(
            id: UUID(),
            coordinate: coordinate,
            address: nil,
            name: name,
            source: .unknown,
            capturedAt: .now
        )
    }
}

private struct CandidateEvaluationResult {
    let acceptedCandidates: [EvaluatedCyclingPathCandidate]
    let decisions: [CyclingPathRouteCandidateDecision]
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

struct CyclingPathRoutePlanningResult {
    let route: Route
    let trace: CyclingPathRouteDecisionTrace
}

struct CyclingPathRouteDecisionTrace {
    let excursionAnchorCount: Int
    let compatibleAnchorPairCount: Int
    let candidateExcursionCount: Int
    let viableCandidateCount: Int
    let candidateDecisions: [CyclingPathRouteCandidateDecision]
    let selectedCandidateID: String?

    static let empty = CyclingPathRouteDecisionTrace(
        excursionAnchorCount: 0,
        compatibleAnchorPairCount: 0,
        candidateExcursionCount: 0,
        viableCandidateCount: 0,
        candidateDecisions: [],
        selectedCandidateID: nil
    )
}

struct CyclingPathRouteCandidateDecision: Identifiable {
    let id: String
    let cyclingPathDistanceMeters: Double
    let outcome: CyclingPathRouteCandidateOutcome
}

enum CyclingPathRouteCandidateOutcome {
    case connectorRouteUnavailable
    case invalidConfiguration
    case exceededTimePenalty(addedTime: TimeInterval)
    case viable
}
