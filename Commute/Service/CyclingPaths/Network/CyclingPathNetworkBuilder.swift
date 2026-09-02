import Foundation

struct CyclingPathNetworkBuilder {
    private struct SpatialCell: Hashable {
        let latitudeIndex: Int
        let longitudeIndex: Int
    }

    private struct UndirectedVertexPair: Hashable {
        let lowerVertexID: CyclingPathNetwork.VertexID
        let higherVertexID: CyclingPathNetwork.VertexID

        init(
            _ firstVertexID: CyclingPathNetwork.VertexID,
            _ secondVertexID: CyclingPathNetwork.VertexID
        ) {
            if firstVertexID.rawValue < secondVertexID.rawValue {
                lowerVertexID = firstVertexID
                higherVertexID = secondVertexID
            } else {
                lowerVertexID = secondVertexID
                higherVertexID = firstVertexID
            }
        }
    }

    private struct SegmentVertex {
        let segmentID: String
        let vertexID: CyclingPathNetwork.VertexID
        let coordinate: LocationCoordinate
        let isEndpoint: Bool
    }

    private let geometry = CyclingPathGeometry()
    private let topologyBuilder = CyclingPathNetworkTopologyBuilder()

    func makeNetwork(
        from segments: [CyclingPathSegment],
        maximumConnectionDistanceMeters: Double
    ) -> CyclingPathNetwork {
        var verticesByID: [CyclingPathNetwork.VertexID: CyclingPathNetwork.Vertex] = [:]
        var edgesByID: [CyclingPathNetwork.EdgeID: CyclingPathNetwork.Edge] = [:]
        var segmentVertices: [SegmentVertex] = []
        var nextVertexRawValue = 0
        var nextEdgeRawValue = 0

        for segment in segments where segment.coordinates.count >= 2 {
            var previousVertexID: CyclingPathNetwork.VertexID?

            for coordinateIndex in segment.coordinates.indices {
                let coordinate = segment.coordinates[coordinateIndex]
                let vertexID = CyclingPathNetwork.VertexID(rawValue: nextVertexRawValue)
                nextVertexRawValue += 1
                verticesByID[vertexID] = CyclingPathNetwork.Vertex(
                    id: vertexID,
                    coordinate: coordinate
                )
                segmentVertices.append(
                    SegmentVertex(
                        segmentID: segment.id,
                        vertexID: vertexID,
                        coordinate: coordinate,
                        isEndpoint: coordinateIndex == segment.coordinates.startIndex
                            || coordinateIndex == segment.coordinates.index(before: segment.coordinates.endIndex)
                    )
                )

                if let previousVertexID,
                   let previousCoordinate = verticesByID[previousVertexID]?.coordinate {
                    let distanceMeters = geometry.distance(from: previousCoordinate, to: coordinate)
                    if distanceMeters > 0 {
                        let edgeID = CyclingPathNetwork.EdgeID(rawValue: nextEdgeRawValue)
                        nextEdgeRawValue += 1
                        edgesByID[edgeID] = CyclingPathNetwork.Edge(
                            id: edgeID,
                            firstVertexID: previousVertexID,
                            secondVertexID: vertexID,
                            coordinates: [previousCoordinate, coordinate],
                            distanceMeters: distanceMeters,
                            kind: .cyclingPath(segmentID: segment.id)
                        )
                    }
                }

                previousVertexID = vertexID
            }
        }

        addShortConnectionEdges(
            between: segmentVertices,
            maximumDistanceMeters: maximumConnectionDistanceMeters,
            nextEdgeRawValue: &nextEdgeRawValue,
            edgesByID: &edgesByID
        )

        return topologyBuilder.makeNetwork(
            verticesByID: verticesByID,
            edgesByID: edgesByID
        )
    }

    private func addShortConnectionEdges(
        between segmentVertices: [SegmentVertex],
        maximumDistanceMeters: Double,
        nextEdgeRawValue: inout Int,
        edgesByID: inout [CyclingPathNetwork.EdgeID: CyclingPathNetwork.Edge]
    ) {
        guard maximumDistanceMeters > 0 else { return }

        var verticesBySpatialCell: [SpatialCell: [SegmentVertex]] = [:]
        for segmentVertex in segmentVertices {
            let spatialCell = spatialCell(
                containing: segmentVertex.coordinate,
                cellSizeMeters: maximumDistanceMeters
            )
            verticesBySpatialCell[spatialCell, default: []].append(segmentVertex)
        }

        var connectedVertexPairs: Set<UndirectedVertexPair> = []
        for endpointVertex in segmentVertices where endpointVertex.isEndpoint {
            let endpointCell = spatialCell(
                containing: endpointVertex.coordinate,
                cellSizeMeters: maximumDistanceMeters
            )
            for nearbyCell in neighboringCells(around: endpointCell) {
                for nearbyVertex in verticesBySpatialCell[nearbyCell, default: []] {
                    guard endpointVertex.segmentID != nearbyVertex.segmentID else { continue }

                    let vertexPair = UndirectedVertexPair(
                        endpointVertex.vertexID,
                        nearbyVertex.vertexID
                    )
                    guard !connectedVertexPairs.contains(vertexPair) else { continue }

                    let connectionDistanceMeters = geometry.distance(
                        from: endpointVertex.coordinate,
                        to: nearbyVertex.coordinate
                    )
                    guard connectionDistanceMeters <= maximumDistanceMeters else { continue }

                    connectedVertexPairs.insert(vertexPair)
                    let edgeID = CyclingPathNetwork.EdgeID(rawValue: nextEdgeRawValue)
                    nextEdgeRawValue += 1
                    edgesByID[edgeID] = CyclingPathNetwork.Edge(
                        id: edgeID,
                        firstVertexID: endpointVertex.vertexID,
                        secondVertexID: nearbyVertex.vertexID,
                        coordinates: [endpointVertex.coordinate, nearbyVertex.coordinate],
                        distanceMeters: connectionDistanceMeters,
                        kind: .shortConnection
                    )
                }
            }
        }
    }

    private func spatialCell(
        containing coordinate: LocationCoordinate,
        cellSizeMeters: Double
    ) -> SpatialCell {
        let latitudeMeters = coordinate.latitude
            * Preferences.CyclingPaths.metersPerLatitudeDegree
        // A fixed longitude conversion keeps the bucket coordinate system stable
        // across the small latitude range covered by Singapore's path dataset.
        // The exact distance check below still decides whether a connection is allowed.
        let longitudeMeters = coordinate.longitude
            * Preferences.CyclingPaths.metersPerLongitudeDegree(at: 0)
        return SpatialCell(
            latitudeIndex: Int(floor(latitudeMeters / cellSizeMeters)),
            longitudeIndex: Int(floor(longitudeMeters / cellSizeMeters))
        )
    }

    private func neighboringCells(around centerCell: SpatialCell) -> [SpatialCell] {
        var neighboringCells: [SpatialCell] = []
        for latitudeOffset in -1...1 {
            for longitudeOffset in -1...1 {
                neighboringCells.append(
                    SpatialCell(
                        latitudeIndex: centerCell.latitudeIndex + latitudeOffset,
                        longitudeIndex: centerCell.longitudeIndex + longitudeOffset
                    )
                )
            }
        }
        return neighboringCells
    }
}
