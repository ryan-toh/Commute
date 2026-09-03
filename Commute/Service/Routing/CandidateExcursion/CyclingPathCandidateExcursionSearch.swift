//
//  CyclingPathCandidateExcursionSearch.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Foundation

/// All limits used while converting a permanent cycling-path network into a
/// bounded set of route-specific excursions.
struct CyclingPathCandidateExcursionSearchConfiguration {
    let maximumAnchorDistanceFromBaselineMeters: Double
    let maximumProjectionsPerBaselineCoordinate: Int
    let maximumAnchorCount: Int
    let minimumForwardProgressMeters: Double
    let maximumAnchorPairCount: Int
    let maximumNetworkRouteDistanceMeters: Double
    let minimumCyclingPathDistanceMeters: Double
    let minimumDestinationProgressMeters: Double
    let maximumNetworkDistanceToBaselineProgressRatio: Double
    let maximumReturnedExcursionCount: Int
}

struct CyclingPathCandidateExcursionSearchResult {
    let excursions: [CyclingPathExcursion]
    let generatedAnchorCount: Int
    let compatibleAnchorPairCount: Int
}

/// Finds useful cycling-path portions without making any MapKit requests.
/// MapKit bridges are deliberately evaluated later because they are expensive.
struct CyclingPathCandidateExcursionSearch {
    private let anchorGenerator = CyclingPathExcursionAnchorGenerator()
    private let pairGenerator = CyclingPathExcursionPairGenerator()
    private let queryGraphBuilder = CyclingPathQueryGraphBuilder()
    private let shortestPathSearch = CyclingPathShortestPathSearch()
    private let excursionFilter = CyclingPathExcursionFilter()

    func findExcursions(
        near baselineRoute: Route,
        destinationCoordinate: LocationCoordinate,
        in permanentNetwork: CyclingPathNetwork,
        configuration: CyclingPathCandidateExcursionSearchConfiguration
    ) -> CyclingPathCandidateExcursionSearchResult {
        let anchors = anchorGenerator.anchors(
            near: baselineRoute,
            in: permanentNetwork,
            maximumDistanceFromBaselineMeters: configuration.maximumAnchorDistanceFromBaselineMeters,
            maximumProjectionsPerBaselineCoordinate: configuration.maximumProjectionsPerBaselineCoordinate,
            maximumAnchorCount: configuration.maximumAnchorCount
        )
        let compatibleAnchorPairs = pairGenerator.pairs(
            from: anchors,
            minimumForwardProgressMeters: configuration.minimumForwardProgressMeters,
            maximumPairCount: configuration.maximumAnchorPairCount
        )

        let virtualVertexRequests = anchors.map { anchor in
            CyclingPathQueryGraph.VirtualVertexRequest(
                identifier: anchor.queryGraphRequestIdentifier,
                projection: anchor.cyclingPathProjection
            )
        }
        let queryGraph = queryGraphBuilder.makeQueryGraph(
            from: permanentNetwork,
            inserting: virtualVertexRequests
        )

        var usefulExcursions: [CyclingPathExcursion] = []
        for anchorPair in compatibleAnchorPairs {
            guard let entryVertexID = queryGraph.vertexID(
                forRequestIdentifier: anchorPair.entryAnchor.queryGraphRequestIdentifier
            ), let exitVertexID = queryGraph.vertexID(
                forRequestIdentifier: anchorPair.exitAnchor.queryGraphRequestIdentifier
            ), let networkRoute = shortestPathSearch.shortestRoute(
                from: entryVertexID,
                to: exitVertexID,
                in: queryGraph.network,
                maximumDistanceMeters: configuration.maximumNetworkRouteDistanceMeters
            ) else {
                continue
            }

            let excursion = CyclingPathExcursion(
                identifier: "excursion-\(anchorPair.entryAnchor.id.rawValue)-\(anchorPair.exitAnchor.id.rawValue)",
                entryAnchor: anchorPair.entryAnchor,
                exitAnchor: anchorPair.exitAnchor,
                networkRoute: networkRoute
            )
            let rejectionReason = excursionFilter.rejectionReason(
                for: excursion,
                destinationCoordinate: destinationCoordinate,
                minimumCyclingPathDistanceMeters: configuration.minimumCyclingPathDistanceMeters,
                minimumForwardProgressMeters: configuration.minimumForwardProgressMeters,
                minimumDestinationProgressMeters: configuration.minimumDestinationProgressMeters,
                maximumDistanceToBaselineProgressRatio: configuration.maximumNetworkDistanceToBaselineProgressRatio
            )
            guard rejectionReason == nil else { continue }
            usefulExcursions.append(excursion)
        }

        let longestUsefulExcursionsFirst = usefulExcursions.sorted { first, second in
            first.networkRoute.cyclingPathDistanceMeters
                > second.networkRoute.cyclingPathDistanceMeters
        }
        return CyclingPathCandidateExcursionSearchResult(
            excursions: Array(
                longestUsefulExcursionsFirst.prefix(configuration.maximumReturnedExcursionCount)
            ),
            generatedAnchorCount: anchors.count,
            compatibleAnchorPairCount: compatibleAnchorPairs.count
        )
    }
}
