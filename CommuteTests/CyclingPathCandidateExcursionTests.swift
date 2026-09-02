import Foundation
import Testing
@testable import Commute

struct CyclingPathCandidateExcursionTests {
    @Test func searchFindsAForwardExcursionAlongTheCyclingPathNetwork() {
        let baselineRoute = makeRoute(
            coordinates: [
                LocationCoordinate(latitude: 1, longitude: 103),
                LocationCoordinate(latitude: 1, longitude: 103.002),
                LocationCoordinate(latitude: 1, longitude: 103.004)
            ],
            distanceMeters: 445,
            expectedTravelTime: 100
        )
        let cyclingPath = CyclingPathSegment(
            id: "parallel-path",
            name: nil,
            lengthMeters: nil,
            coordinates: [
                LocationCoordinate(latitude: 1.000_1, longitude: 103),
                LocationCoordinate(latitude: 1.000_1, longitude: 103.002),
                LocationCoordinate(latitude: 1.000_1, longitude: 103.004)
            ]
        )
        let network = CyclingPathNetworkBuilder().makeNetwork(
            from: [cyclingPath],
            maximumConnectionDistanceMeters: 0
        )
        let configuration = CyclingPathCandidateExcursionSearchConfiguration(
            maximumAnchorDistanceFromBaselineMeters: 20,
            maximumProjectionsPerBaselineCoordinate: 2,
            maximumAnchorCount: 10,
            minimumForwardProgressMeters: 20,
            maximumAnchorPairCount: 10,
            maximumNetworkRouteDistanceMeters: 1_000,
            minimumCyclingPathDistanceMeters: 20,
            minimumDestinationProgressMeters: 20,
            maximumNetworkDistanceToBaselineProgressRatio: 1.1,
            maximumReturnedExcursionCount: 5
        )

        let result = CyclingPathCandidateExcursionSearch().findExcursions(
            near: baselineRoute,
            destinationCoordinate: baselineRoute.coordinates.last!,
            in: network,
            configuration: configuration
        )

        #expect(result.generatedAnchorCount >= 2)
        #expect(result.compatibleAnchorPairCount >= 1)
        #expect(result.excursions.isEmpty == false)
    }

    @Test func filterRejectsAnExcursionThatDoesNotApproachTheDestination() {
        let excursion = makeExcursion(
            entryCoordinate: LocationCoordinate(latitude: 1, longitude: 103.002),
            exitCoordinate: LocationCoordinate(latitude: 1, longitude: 103.001),
            entryBaselineProgressMeters: 100,
            exitBaselineProgressMeters: 300,
            networkDistanceMeters: 200,
            cyclingPathDistanceMeters: 200
        )

        let rejection = CyclingPathExcursionFilter().rejectionReason(
            for: excursion,
            destinationCoordinate: LocationCoordinate(latitude: 1, longitude: 103.004),
            minimumCyclingPathDistanceMeters: 100,
            minimumForwardProgressMeters: 100,
            minimumDestinationProgressMeters: 50,
            maximumDistanceToBaselineProgressRatio: 1.5
        )

        #expect(rejection == .insufficientDestinationProgress)
    }

    @Test func evaluatorRejectsACandidateOverThePercentageTimeLimit() {
        let excursion = makeExcursion(
            entryCoordinate: LocationCoordinate(latitude: 1, longitude: 103),
            exitCoordinate: LocationCoordinate(latitude: 1, longitude: 103.001),
            entryBaselineProgressMeters: 0,
            exitBaselineProgressMeters: 100,
            networkDistanceMeters: 90,
            cyclingPathDistanceMeters: 90
        )
        let directRoute = makeRoute(
            coordinates: [excursion.entryCoordinate, excursion.exitCoordinate],
            distanceMeters: 100,
            expectedTravelTime: 100
        )
        let bridges = CyclingPathBridges(
            approachRoute: makeRoute(
                coordinates: [excursion.entryCoordinate, excursion.entryCoordinate],
                distanceMeters: 0,
                expectedTravelTime: 50
            ),
            departureRoute: makeRoute(
                coordinates: [excursion.exitCoordinate, excursion.exitCoordinate],
                distanceMeters: 0,
                expectedTravelTime: 50
            )
        )

        let evaluation = CyclingPathCandidateEvaluator().evaluate(
            excursion: excursion,
            bridges: bridges,
            directRoute: directRoute,
            assumedCyclingSpeedMetersPerSecond: 4.5,
            maximumAddedTravelTimePercentage: 0.1
        )

        if case let .rejectedForTravelTime(addedTravelTime) = evaluation {
            #expect(addedTravelTime == 20)
        } else {
            Issue.record("Expected the candidate to exceed the 10% travel-time limit")
        }
    }

    @Test func rankerPrefersMoreCyclingPathDistanceAmongViableCandidates() {
        let shorterExcursion = makeExcursion(
            entryCoordinate: LocationCoordinate(latitude: 1, longitude: 103),
            exitCoordinate: LocationCoordinate(latitude: 1, longitude: 103.001),
            entryBaselineProgressMeters: 0,
            exitBaselineProgressMeters: 100,
            networkDistanceMeters: 100,
            cyclingPathDistanceMeters: 80
        )
        let longerExcursion = makeExcursion(
            entryCoordinate: LocationCoordinate(latitude: 1, longitude: 103),
            exitCoordinate: LocationCoordinate(latitude: 1, longitude: 103.002),
            entryBaselineProgressMeters: 0,
            exitBaselineProgressMeters: 200,
            networkDistanceMeters: 200,
            cyclingPathDistanceMeters: 180
        )
        let shorterCandidate = makeEvaluatedCandidate(
            excursion: shorterExcursion,
            totalTravelTime: 90
        )
        let longerCandidate = makeEvaluatedCandidate(
            excursion: longerExcursion,
            totalTravelTime: 100
        )

        let preferredCandidate = CyclingPathCandidateRanker().preferredCandidate(
            from: [shorterCandidate, longerCandidate]
        )

        #expect(preferredCandidate?.excursion.identifier == longerExcursion.identifier)
    }

    @Test func assemblerJoinsBridgeAndCyclingPathCoordinatesWithoutDuplicateJunctions() {
        let entryCoordinate = LocationCoordinate(latitude: 1, longitude: 103.001)
        let exitCoordinate = LocationCoordinate(latitude: 1, longitude: 103.002)
        let excursion = makeExcursion(
            entryCoordinate: entryCoordinate,
            exitCoordinate: exitCoordinate,
            entryBaselineProgressMeters: 100,
            exitBaselineProgressMeters: 200,
            networkDistanceMeters: 100,
            cyclingPathDistanceMeters: 100
        )
        let originCoordinate = LocationCoordinate(latitude: 1, longitude: 103)
        let destinationCoordinate = LocationCoordinate(latitude: 1, longitude: 103.003)
        let bridges = CyclingPathBridges(
            approachRoute: makeRoute(
                coordinates: [originCoordinate, entryCoordinate],
                distanceMeters: 100,
                expectedTravelTime: 20
            ),
            departureRoute: makeRoute(
                coordinates: [exitCoordinate, destinationCoordinate],
                distanceMeters: 100,
                expectedTravelTime: 20
            )
        )
        let candidate = EvaluatedCyclingPathCandidate(
            excursion: excursion,
            bridges: bridges,
            cyclingPathTravelTime: 20,
            totalTravelTime: 60,
            totalDistanceMeters: 300
        )

        let assembledRoute = CyclingPathRouteAssembler().assembleRoute(from: candidate)

        #expect(assembledRoute.coordinates == [
            originCoordinate,
            entryCoordinate,
            exitCoordinate,
            destinationCoordinate
        ])
        #expect(assembledRoute.steps.count == 1)
        #expect(assembledRoute.steps.first?.source == .curatedPath)
    }

    private func makeExcursion(
        entryCoordinate: LocationCoordinate,
        exitCoordinate: LocationCoordinate,
        entryBaselineProgressMeters: Double,
        exitBaselineProgressMeters: Double,
        networkDistanceMeters: Double,
        cyclingPathDistanceMeters: Double
    ) -> CyclingPathExcursion {
        let edgeID = CyclingPathNetwork.EdgeID(rawValue: 0)
        let entryAnchor = makeAnchor(
            id: 0,
            coordinate: entryCoordinate,
            edgeID: edgeID,
            baselineProgressMeters: entryBaselineProgressMeters
        )
        let exitAnchor = makeAnchor(
            id: 1,
            coordinate: exitCoordinate,
            edgeID: edgeID,
            baselineProgressMeters: exitBaselineProgressMeters
        )
        return CyclingPathExcursion(
            identifier: "test-excursion-\(entryBaselineProgressMeters)-\(exitBaselineProgressMeters)",
            entryAnchor: entryAnchor,
            exitAnchor: exitAnchor,
            networkRoute: CyclingPathNetworkRoute(
                coordinates: [entryCoordinate, exitCoordinate],
                totalDistanceMeters: networkDistanceMeters,
                cyclingPathDistanceMeters: cyclingPathDistanceMeters
            )
        )
    }

    private func makeAnchor(
        id: Int,
        coordinate: LocationCoordinate,
        edgeID: CyclingPathNetwork.EdgeID,
        baselineProgressMeters: Double
    ) -> CyclingPathExcursionAnchor {
        CyclingPathExcursionAnchor(
            id: .init(rawValue: id),
            cyclingPathProjection: CyclingPathProjection(
                edgeID: edgeID,
                coordinate: coordinate,
                fractionAlongEdge: 0.5,
                distanceFromQueryMeters: 0,
                distanceFromEdgeStartMeters: 0
            ),
            baselineProgressMeters: baselineProgressMeters,
            networkComponentID: 0
        )
    }

    private func makeEvaluatedCandidate(
        excursion: CyclingPathExcursion,
        totalTravelTime: TimeInterval
    ) -> EvaluatedCyclingPathCandidate {
        let emptyApproachRoute = makeRoute(
            coordinates: [excursion.entryCoordinate, excursion.entryCoordinate],
            distanceMeters: 0,
            expectedTravelTime: 0
        )
        let emptyDepartureRoute = makeRoute(
            coordinates: [excursion.exitCoordinate, excursion.exitCoordinate],
            distanceMeters: 0,
            expectedTravelTime: 0
        )
        return EvaluatedCyclingPathCandidate(
            excursion: excursion,
            bridges: CyclingPathBridges(
                approachRoute: emptyApproachRoute,
                departureRoute: emptyDepartureRoute
            ),
            cyclingPathTravelTime: totalTravelTime,
            totalTravelTime: totalTravelTime,
            totalDistanceMeters: excursion.networkRoute.totalDistanceMeters
        )
    }

    private func makeRoute(
        coordinates: [LocationCoordinate],
        distanceMeters: Double,
        expectedTravelTime: TimeInterval
    ) -> Route {
        Route(
            id: UUID(),
            coordinates: coordinates,
            steps: [],
            distanceMeters: distanceMeters,
            expectedTravelTime: expectedTravelTime,
            transportMode: .cycling
        )
    }
}
