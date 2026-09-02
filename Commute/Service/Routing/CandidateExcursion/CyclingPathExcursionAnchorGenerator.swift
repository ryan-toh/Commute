import Foundation

struct CyclingPathExcursionAnchor {
    struct ID: Hashable, Sendable {
        let rawValue: Int
    }

    let id: ID
    let cyclingPathProjection: CyclingPathProjection
    let baselineProgressMeters: Double
    let networkComponentID: Int

    var queryGraphRequestIdentifier: String {
        "cycling-path-anchor-\(id.rawValue)"
    }
}

struct CyclingPathExcursionAnchorGenerator {
    private let cyclingPathProjector = CyclingPathProjector()
    private let baselineProjector = RouteBaselineProjector()

    func anchors(
        near baselineRoute: Route,
        in network: CyclingPathNetwork,
        maximumDistanceFromBaselineMeters: Double,
        maximumProjectionsPerBaselineCoordinate: Int,
        maximumAnchorCount: Int
    ) -> [CyclingPathExcursionAnchor] {
        var bestProjectionByEdgeID: [CyclingPathNetwork.EdgeID: CyclingPathProjection] = [:]

        for baselineCoordinate in baselineRoute.coordinates {
            let nearbyProjections = cyclingPathProjector.nearestProjections(
                to: baselineCoordinate,
                in: network,
                maximumDistanceMeters: maximumDistanceFromBaselineMeters,
                maximumResultCount: maximumProjectionsPerBaselineCoordinate
            )
            for projection in nearbyProjections {
                if projection.distanceFromQueryMeters
                    < (bestProjectionByEdgeID[projection.edgeID]?.distanceFromQueryMeters ?? .infinity) {
                    bestProjectionByEdgeID[projection.edgeID] = projection
                }
            }
        }

        let anchorCandidates = bestProjectionByEdgeID.values.compactMap {
            projection -> (projection: CyclingPathProjection, progress: Double, componentID: Int)? in
            guard let edge = network.edge(withID: projection.edgeID),
                  let componentID = network.componentID(containing: edge.firstVertexID),
                  let baselineProjection = baselineProjector.project(
                    projection.coordinate,
                    onto: baselineRoute.coordinates
                  ) else {
                return nil
            }
            return (projection, baselineProjection.progressFromRouteStartMeters, componentID)
        }
        .sorted { first, second in
            if first.progress == second.progress {
                return first.projection.distanceFromQueryMeters < second.projection.distanceFromQueryMeters
            }
            return first.progress < second.progress
        }
        .prefix(maximumAnchorCount)

        return anchorCandidates.enumerated().map { index, candidate in
            CyclingPathExcursionAnchor(
                id: .init(rawValue: index),
                cyclingPathProjection: candidate.projection,
                baselineProgressMeters: candidate.progress,
                networkComponentID: candidate.componentID
            )
        }
    }
}
