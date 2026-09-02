import Foundation

/// Builds the lookup indexes that describe connectivity in a cycling-path network.
struct CyclingPathNetworkTopologyBuilder {
    func makeNetwork(
        verticesByID: [CyclingPathNetwork.VertexID: CyclingPathNetwork.Vertex],
        edgesByID: [CyclingPathNetwork.EdgeID: CyclingPathNetwork.Edge]
    ) -> CyclingPathNetwork {
        let edgeIDsByVertexID = makeAdjacencyIndex(from: edgesByID)
        let componentIDByVertexID = makeConnectedComponentIndex(
            verticesByID: verticesByID,
            edgesByID: edgesByID,
            edgeIDsByVertexID: edgeIDsByVertexID
        )
        return CyclingPathNetwork(
            verticesByID: verticesByID,
            edgesByID: edgesByID,
            edgeIDsByVertexID: edgeIDsByVertexID,
            componentIDByVertexID: componentIDByVertexID
        )
    }

    private func makeAdjacencyIndex(
        from edgesByID: [CyclingPathNetwork.EdgeID: CyclingPathNetwork.Edge]
    ) -> [CyclingPathNetwork.VertexID: [CyclingPathNetwork.EdgeID]] {
        var edgeIDsByVertexID: [CyclingPathNetwork.VertexID: [CyclingPathNetwork.EdgeID]] = [:]

        for edge in edgesByID.values {
            edgeIDsByVertexID[edge.firstVertexID, default: []].append(edge.id)
            edgeIDsByVertexID[edge.secondVertexID, default: []].append(edge.id)
        }
        return edgeIDsByVertexID
    }

    private func makeConnectedComponentIndex(
        verticesByID: [CyclingPathNetwork.VertexID: CyclingPathNetwork.Vertex],
        edgesByID: [CyclingPathNetwork.EdgeID: CyclingPathNetwork.Edge],
        edgeIDsByVertexID: [CyclingPathNetwork.VertexID: [CyclingPathNetwork.EdgeID]]
    ) -> [CyclingPathNetwork.VertexID: Int] {
        var componentIDByVertexID: [CyclingPathNetwork.VertexID: Int] = [:]
        var nextComponentID = 0

        for vertexID in verticesByID.keys where componentIDByVertexID[vertexID] == nil {
            var pendingVertexIDs = [vertexID]
            componentIDByVertexID[vertexID] = nextComponentID

            while let currentVertexID = pendingVertexIDs.popLast() {
                for edgeID in edgeIDsByVertexID[currentVertexID, default: []] {
                    guard let edge = edgesByID[edgeID],
                          let connectedVertexID = edge.oppositeVertexID(from: currentVertexID),
                          componentIDByVertexID[connectedVertexID] == nil else {
                        continue
                    }
                    componentIDByVertexID[connectedVertexID] = nextComponentID
                    pendingVertexIDs.append(connectedVertexID)
                }
            }

            nextComponentID += 1
        }
        return componentIDByVertexID
    }
}
