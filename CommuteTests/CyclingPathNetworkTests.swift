import Foundation
import Testing
@testable import Commute

struct CyclingPathNetworkTests {
    @Test func networkUsesEverySegmentCoordinateAsAVertex() {
        let segment = makeSegment(
            id: "path",
            longitudes: [103, 103.001, 103.002]
        )

        let network = CyclingPathNetworkBuilder().makeNetwork(
            from: [segment],
            maximumConnectionDistanceMeters: 0
        )

        #expect(network.verticesByID.count == 3)
        #expect(network.edgesByID.count == 2)
    }

    @Test func projectorCanReturnAPointInsideAnEdge() throws {
        let network = CyclingPathNetworkBuilder().makeNetwork(
            from: [makeSegment(id: "path", longitudes: [103, 103.002])],
            maximumConnectionDistanceMeters: 0
        )

        let projection = try #require(
            CyclingPathProjector().nearestProjections(
                to: LocationCoordinate(latitude: 1, longitude: 103.001),
                in: network,
                maximumDistanceMeters: 10,
                maximumResultCount: 1
            ).first
        )

        #expect(abs(projection.fractionAlongEdge - 0.5) < 0.000_001)
        #expect(abs(projection.coordinate.longitude - 103.001) < 0.000_001)
    }

    @Test func queryGraphSplitsAnEdgeAtAVirtualVertex() throws {
        let permanentNetwork = CyclingPathNetworkBuilder().makeNetwork(
            from: [makeSegment(id: "path", longitudes: [103, 103.002])],
            maximumConnectionDistanceMeters: 0
        )
        let projection = try #require(
            CyclingPathProjector().nearestProjections(
                to: LocationCoordinate(latitude: 1, longitude: 103.001),
                in: permanentNetwork,
                maximumDistanceMeters: 10,
                maximumResultCount: 1
            ).first
        )

        let queryGraph = CyclingPathQueryGraphBuilder().makeQueryGraph(
            from: permanentNetwork,
            inserting: [
                .init(identifier: "middle", projection: projection)
            ]
        )

        #expect(queryGraph.vertexID(forRequestIdentifier: "middle") != nil)
        #expect(queryGraph.network.edgesByID.count == 2)
        let splitDistance = queryGraph.network.edgesByID.values.reduce(0) {
            $0 + $1.distanceMeters
        }
        let originalDistance = try #require(permanentNetwork.edgesByID.values.first).distanceMeters
        #expect(abs(splitDistance - originalDistance) < 0.01)
        #expect(permanentNetwork.edgesByID.count == 1)
    }

    @Test func shortestPathSearchUsesTheLowerDistanceChain() throws {
        let directSegment = makeSegment(
            id: "direct",
            longitudes: [103, 103.001, 103.002]
        )
        let detourSegment = CyclingPathSegment(
            id: "detour",
            name: nil,
            lengthMeters: nil,
            coordinates: [
                LocationCoordinate(latitude: 1, longitude: 103),
                LocationCoordinate(latitude: 1.002, longitude: 103.001),
                LocationCoordinate(latitude: 1, longitude: 103.002)
            ]
        )
        let network = CyclingPathNetworkBuilder().makeNetwork(
            from: [directSegment, detourSegment],
            maximumConnectionDistanceMeters: 1
        )
        let startVertexID = try #require(
            network.verticesByID.values
                .filter { $0.coordinate == directSegment.coordinates.first }
                .min { $0.id.rawValue < $1.id.rawValue }?.id
        )
        let destinationVertexID = try #require(
            network.verticesByID.values
                .filter { $0.coordinate == directSegment.coordinates.last }
                .min { $0.id.rawValue < $1.id.rawValue }?.id
        )

        let route = CyclingPathShortestPathSearch().shortestRoute(
            from: startVertexID,
            to: destinationVertexID,
            in: network,
            maximumDistanceMeters: 2_000
        )

        #expect(route?.coordinates.contains(directSegment.coordinates[1]) == true)
        #expect(route?.coordinates.contains(detourSegment.coordinates[1]) == false)
    }

    @Test func networkCanConnectAnEndpointToAnotherSegmentsInteriorVertex() throws {
        let firstSegment = makeSegment(
            id: "first",
            longitudes: [103, 103.001, 103.002]
        )
        let secondSegment = CyclingPathSegment(
            id: "second",
            name: nil,
            lengthMeters: nil,
            coordinates: [
                LocationCoordinate(latitude: 1.001, longitude: 103.001),
                LocationCoordinate(latitude: 1.000_01, longitude: 103.001)
            ]
        )

        let network = CyclingPathNetworkBuilder().makeNetwork(
            from: [firstSegment, secondSegment],
            maximumConnectionDistanceMeters: 5
        )
        let connectionEdge = network.edgesByID.values.first { edge in
            if case .shortConnection = edge.kind {
                return true
            }
            return false
        }

        #expect(connectionEdge != nil)
        #expect(connectionEdge?.coordinates.contains(firstSegment.coordinates[1]) == true)
        #expect(connectionEdge?.coordinates.contains(secondSegment.coordinates.last!) == true)
    }

    private func makeSegment(id: String, longitudes: [Double]) -> CyclingPathSegment {
        CyclingPathSegment(
            id: id,
            name: nil,
            lengthMeters: nil,
            coordinates: longitudes.map {
                LocationCoordinate(latitude: 1, longitude: $0)
            }
        )
    }
}
