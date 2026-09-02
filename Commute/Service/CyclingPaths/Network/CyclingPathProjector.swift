import Foundation

struct CyclingPathProjection {
    let edgeID: CyclingPathNetwork.EdgeID
    let coordinate: LocationCoordinate
    let fractionAlongEdge: Double
    let distanceFromQueryMeters: Double
    let distanceFromEdgeStartMeters: Double
}

struct CyclingPathProjector {
    private let geometry = CyclingPathGeometry()

    func nearestProjections(
        to queryCoordinate: LocationCoordinate,
        in network: CyclingPathNetwork,
        maximumDistanceMeters: Double,
        maximumResultCount: Int
    ) -> [CyclingPathProjection] {
        guard maximumResultCount > 0 else { return [] }

        var projections: [CyclingPathProjection] = []
        for edge in network.edgesByID.values {
            guard case .cyclingPath = edge.kind,
                  let edgeStart = edge.coordinates.first,
                  let edgeEnd = edge.coordinates.last,
                  let coordinateProjection = geometry.projection(
                    of: queryCoordinate,
                    onto: edgeStart,
                    and: edgeEnd
                  ),
                  coordinateProjection.distanceFromQueryMeters <= maximumDistanceMeters else {
                continue
            }

            projections.append(
                CyclingPathProjection(
                    edgeID: edge.id,
                    coordinate: coordinateProjection.coordinate,
                    fractionAlongEdge: coordinateProjection.fractionAlongEdge,
                    distanceFromQueryMeters: coordinateProjection.distanceFromQueryMeters,
                    distanceFromEdgeStartMeters: coordinateProjection.distanceFromEdgeStartMeters
                )
            )
        }

        return Array(
            projections
                .sorted { first, second in
                    if first.distanceFromQueryMeters == second.distanceFromQueryMeters {
                        return first.edgeID.rawValue < second.edgeID.rawValue
                    }
                    return first.distanceFromQueryMeters < second.distanceFromQueryMeters
                }
                .prefix(maximumResultCount)
        )
    }
}
