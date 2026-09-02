import Foundation

struct CyclingPathQueryGraph {
    struct VirtualVertexRequest {
        let identifier: String
        let projection: CyclingPathProjection
    }

    let network: CyclingPathNetwork
    let vertexIDByRequestIdentifier: [String: CyclingPathNetwork.VertexID]

    func vertexID(forRequestIdentifier identifier: String) -> CyclingPathNetwork.VertexID? {
        vertexIDByRequestIdentifier[identifier]
    }
}

struct CyclingPathQueryGraphBuilder {
    private let geometry = CyclingPathGeometry()
    private let topologyBuilder = CyclingPathNetworkTopologyBuilder()

    func makeQueryGraph(
        from permanentNetwork: CyclingPathNetwork,
        inserting requests: [CyclingPathQueryGraph.VirtualVertexRequest]
    ) -> CyclingPathQueryGraph {
        var verticesByID = permanentNetwork.verticesByID
        var edgesByID = permanentNetwork.edgesByID
        var vertexIDByRequestIdentifier: [String: CyclingPathNetwork.VertexID] = [:]
        var nextVertexRawValue = (verticesByID.keys.map(\.rawValue).max() ?? -1) + 1
        var nextEdgeRawValue = (edgesByID.keys.map(\.rawValue).max() ?? -1) + 1

        let requestsByEdgeID = Dictionary(grouping: requests, by: { $0.projection.edgeID })
        for (edgeID, edgeRequests) in requestsByEdgeID {
            guard let originalEdge = edgesByID.removeValue(forKey: edgeID) else { continue }

            let sortedRequests = edgeRequests.sorted {
                $0.projection.fractionAlongEdge < $1.projection.fractionAlongEdge
            }
            var orderedVertices: [(vertexID: CyclingPathNetwork.VertexID, coordinate: LocationCoordinate)] = [
                (originalEdge.firstVertexID, originalEdge.coordinates[0])
            ]

            for request in sortedRequests {
                if request.projection.fractionAlongEdge <= 0 {
                    vertexIDByRequestIdentifier[request.identifier] = originalEdge.firstVertexID
                    continue
                }
                if request.projection.fractionAlongEdge >= 1 {
                    vertexIDByRequestIdentifier[request.identifier] = originalEdge.secondVertexID
                    continue
                }
                if let existingVertex = orderedVertices.last,
                   existingVertex.coordinate == request.projection.coordinate {
                    vertexIDByRequestIdentifier[request.identifier] = existingVertex.vertexID
                    continue
                }

                let virtualVertexID = CyclingPathNetwork.VertexID(rawValue: nextVertexRawValue)
                nextVertexRawValue += 1
                verticesByID[virtualVertexID] = CyclingPathNetwork.Vertex(
                    id: virtualVertexID,
                    coordinate: request.projection.coordinate
                )
                orderedVertices.append((virtualVertexID, request.projection.coordinate))
                vertexIDByRequestIdentifier[request.identifier] = virtualVertexID
            }

            orderedVertices.append((originalEdge.secondVertexID, originalEdge.coordinates[1]))
            for (firstVertex, secondVertex) in zip(orderedVertices, orderedVertices.dropFirst()) {
                let splitEdgeCoordinates = [firstVertex.coordinate, secondVertex.coordinate]
                let splitEdgeDistanceMeters = geometry.length(of: splitEdgeCoordinates)
                guard splitEdgeDistanceMeters > 0 else { continue }

                let splitEdgeID = CyclingPathNetwork.EdgeID(rawValue: nextEdgeRawValue)
                nextEdgeRawValue += 1
                edgesByID[splitEdgeID] = CyclingPathNetwork.Edge(
                    id: splitEdgeID,
                    firstVertexID: firstVertex.vertexID,
                    secondVertexID: secondVertex.vertexID,
                    coordinates: splitEdgeCoordinates,
                    distanceMeters: splitEdgeDistanceMeters,
                    kind: originalEdge.kind
                )
            }
        }

        let queryNetwork = topologyBuilder.makeNetwork(
            verticesByID: verticesByID,
            edgesByID: edgesByID
        )

        return CyclingPathQueryGraph(
            network: queryNetwork,
            vertexIDByRequestIdentifier: vertexIDByRequestIdentifier
        )
    }
}
