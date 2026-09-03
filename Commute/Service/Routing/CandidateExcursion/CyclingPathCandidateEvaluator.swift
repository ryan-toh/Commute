//
//  CyclingPathCandidateEvaluator.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Foundation

struct EvaluatedCyclingPathCandidate {
    let excursion: CyclingPathExcursion
    let bridges: CyclingPathBridges
    let cyclingPathTravelTime: TimeInterval
    let totalTravelTime: TimeInterval
    let totalDistanceMeters: Double
}

enum CyclingPathCandidateEvaluation {
    case accepted(EvaluatedCyclingPathCandidate)
    case rejectedForInvalidConfiguration
    case rejectedForTravelTime(addedTravelTime: TimeInterval)
}

struct CyclingPathCandidateEvaluator {
    func evaluate(
        excursion: CyclingPathExcursion,
        bridges: CyclingPathBridges,
        directRoute: Route,
        assumedCyclingSpeedMetersPerSecond: Double,
        maximumAddedTravelTimePercentage: Double
    ) -> CyclingPathCandidateEvaluation {
        guard assumedCyclingSpeedMetersPerSecond > 0,
              maximumAddedTravelTimePercentage >= 0 else {
            return .rejectedForInvalidConfiguration
        }

        let cyclingPathTravelTime = excursion.networkRoute.totalDistanceMeters
            / assumedCyclingSpeedMetersPerSecond
        let totalTravelTime = bridges.approachRoute.expectedTravelTime
            + cyclingPathTravelTime
            + bridges.departureRoute.expectedTravelTime
        let addedTravelTime = totalTravelTime - directRoute.expectedTravelTime

        let maximumAllowedTravelTime = directRoute.expectedTravelTime
            * (1 + maximumAddedTravelTimePercentage)
        guard totalTravelTime <= maximumAllowedTravelTime else {
            return .rejectedForTravelTime(addedTravelTime: addedTravelTime)
        }

        let totalDistanceMeters = bridges.approachRoute.distanceMeters
            + excursion.networkRoute.totalDistanceMeters
            + bridges.departureRoute.distanceMeters
        return .accepted(
            EvaluatedCyclingPathCandidate(
                excursion: excursion,
                bridges: bridges,
                cyclingPathTravelTime: cyclingPathTravelTime,
                totalTravelTime: totalTravelTime,
                totalDistanceMeters: totalDistanceMeters
            )
        )
    }
}

struct CyclingPathCandidateRanker {
    func preferredCandidate(
        from candidates: [EvaluatedCyclingPathCandidate]
    ) -> EvaluatedCyclingPathCandidate? {
        candidates.sorted { first, second in
            let firstCyclingDistance = first.excursion.networkRoute.cyclingPathDistanceMeters
            let secondCyclingDistance = second.excursion.networkRoute.cyclingPathDistanceMeters
            if firstCyclingDistance != secondCyclingDistance {
                return firstCyclingDistance > secondCyclingDistance
            }
            if first.totalTravelTime != second.totalTravelTime {
                return first.totalTravelTime < second.totalTravelTime
            }
            if first.totalDistanceMeters != second.totalDistanceMeters {
                return first.totalDistanceMeters < second.totalDistanceMeters
            }
            return first.excursion.identifier < second.excursion.identifier
        }.first
    }
}
