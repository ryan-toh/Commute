import Foundation

struct CyclingPathNetwork {
    struct VertexID: Hashable, Sendable {
        let rawValue: Int
    }

    struct EdgeID: Hashable, Sendable {
        let rawValue: Int
    }

    struct Vertex {
        let id: VertexID
        let coordinate: LocationCoordinate
    }

    struct Edge {
        enum Kind {
            case cyclingPath(segmentID: String)
            case shortConnection
        }

        let id: EdgeID
        let firstVertexID: VertexID
        let secondVertexID: VertexID
        let coordinates: [LocationCoordinate]
        let distanceMeters: Double
        let kind: Kind

        func oppositeVertexID(from vertexID: VertexID) -> VertexID? {
            if vertexID == firstVertexID {
                return secondVertexID
            }
            if vertexID == secondVertexID {
                return firstVertexID
            }
            return nil
        }

        func coordinates(startingAt vertexID: VertexID) -> [LocationCoordinate]? {
            if vertexID == firstVertexID {
                return coordinates
            }
            if vertexID == secondVertexID {
                return Array(coordinates.reversed())
            }
            return nil
        }
    }

    let verticesByID: [VertexID: Vertex]
    let edgesByID: [EdgeID: Edge]
    let edgeIDsByVertexID: [VertexID: [EdgeID]]
    let componentIDByVertexID: [VertexID: Int]

    func vertex(withID vertexID: VertexID) -> Vertex? {
        verticesByID[vertexID]
    }

    func edge(withID edgeID: EdgeID) -> Edge? {
        edgesByID[edgeID]
    }

    func edges(connectedTo vertexID: VertexID) -> [Edge] {
        edgeIDsByVertexID[vertexID, default: []].compactMap { edgesByID[$0] }
    }

    func componentID(containing vertexID: VertexID) -> Int? {
        componentIDByVertexID[vertexID]
    }
}
