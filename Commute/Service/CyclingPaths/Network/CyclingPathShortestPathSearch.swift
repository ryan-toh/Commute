import Foundation

struct CyclingPathNetworkRoute {
    let coordinates: [LocationCoordinate]
    let totalDistanceMeters: Double
    let cyclingPathDistanceMeters: Double
}

struct CyclingPathShortestPathSearch {
    func shortestRoute(
        from startVertexID: CyclingPathNetwork.VertexID,
        to destinationVertexID: CyclingPathNetwork.VertexID,
        in network: CyclingPathNetwork,
        maximumDistanceMeters: Double
    ) -> CyclingPathNetworkRoute? {
        guard startVertexID != destinationVertexID,
              network.vertex(withID: startVertexID) != nil,
              network.vertex(withID: destinationVertexID) != nil else {
            return nil
        }

        var shortestDistanceByVertexID: [CyclingPathNetwork.VertexID: Double] = [
            startVertexID: 0
        ]
        var precedingStepByVertexID: [CyclingPathNetwork.VertexID: PrecedingRouteStep] = [:]
        var verticesToVisit = MinimumRouteDistanceQueue()
        verticesToVisit.insert(
            VertexDistance(vertexID: startVertexID, distanceFromStartMeters: 0)
        )

        while let currentVertex = verticesToVisit.removeMinimum() {
            guard currentVertex.distanceFromStartMeters
                    == shortestDistanceByVertexID[currentVertex.vertexID],
                  currentVertex.distanceFromStartMeters <= maximumDistanceMeters else {
                continue
            }
            if currentVertex.vertexID == destinationVertexID {
                break
            }

            for edge in network.edges(connectedTo: currentVertex.vertexID) {
                guard let connectedVertexID = edge.oppositeVertexID(from: currentVertex.vertexID) else {
                    continue
                }
                let distanceThroughCurrentVertex = currentVertex.distanceFromStartMeters
                    + edge.distanceMeters
                guard distanceThroughCurrentVertex <= maximumDistanceMeters,
                      distanceThroughCurrentVertex
                        < (shortestDistanceByVertexID[connectedVertexID] ?? .infinity) else {
                    continue
                }

                shortestDistanceByVertexID[connectedVertexID] = distanceThroughCurrentVertex
                precedingStepByVertexID[connectedVertexID] = PrecedingRouteStep(
                    precedingVertexID: currentVertex.vertexID,
                    edgeID: edge.id
                )
                verticesToVisit.insert(
                    VertexDistance(
                        vertexID: connectedVertexID,
                        distanceFromStartMeters: distanceThroughCurrentVertex
                    )
                )
            }
        }

        guard let totalDistanceMeters = shortestDistanceByVertexID[destinationVertexID] else {
            return nil
        }

        var routeSteps: [(startingVertexID: CyclingPathNetwork.VertexID, edge: CyclingPathNetwork.Edge)] = []
        var currentVertexID = destinationVertexID
        while currentVertexID != startVertexID {
            guard let precedingStep = precedingStepByVertexID[currentVertexID],
                  let edge = network.edge(withID: precedingStep.edgeID) else {
                return nil
            }
            routeSteps.append((precedingStep.precedingVertexID, edge))
            currentVertexID = precedingStep.precedingVertexID
        }

        var coordinates: [LocationCoordinate] = []
        var cyclingPathDistanceMeters = 0.0
        for routeStep in routeSteps.reversed() {
            guard let edgeCoordinates = routeStep.edge.coordinates(
                startingAt: routeStep.startingVertexID
            ) else {
                return nil
            }
            appendUniqueCoordinates(edgeCoordinates, to: &coordinates)
            if case .cyclingPath = routeStep.edge.kind {
                cyclingPathDistanceMeters += routeStep.edge.distanceMeters
            }
        }

        guard coordinates.count >= 2 else { return nil }
        return CyclingPathNetworkRoute(
            coordinates: coordinates,
            totalDistanceMeters: totalDistanceMeters,
            cyclingPathDistanceMeters: cyclingPathDistanceMeters
        )
    }

    private func appendUniqueCoordinates(
        _ coordinatesToAppend: [LocationCoordinate],
        to coordinates: inout [LocationCoordinate]
    ) {
        for coordinate in coordinatesToAppend where coordinates.last != coordinate {
            coordinates.append(coordinate)
        }
    }
}

private struct PrecedingRouteStep {
    let precedingVertexID: CyclingPathNetwork.VertexID
    let edgeID: CyclingPathNetwork.EdgeID
}

private struct VertexDistance {
    let vertexID: CyclingPathNetwork.VertexID
    let distanceFromStartMeters: Double
}

private struct MinimumRouteDistanceQueue {
    private var entries: [VertexDistance] = []

    mutating func insert(_ entry: VertexDistance) {
        entries.append(entry)
        var childIndex = entries.count - 1

        while childIndex > 0 {
            let parentIndex = (childIndex - 1) / 2
            guard entries[childIndex].distanceFromStartMeters
                    < entries[parentIndex].distanceFromStartMeters else {
                break
            }
            entries.swapAt(childIndex, parentIndex)
            childIndex = parentIndex
        }
    }

    mutating func removeMinimum() -> VertexDistance? {
        guard !entries.isEmpty else { return nil }
        if entries.count == 1 {
            return entries.removeLast()
        }

        let minimumEntry = entries[0]
        entries[0] = entries.removeLast()
        var parentIndex = 0

        while true {
            let leftChildIndex = parentIndex * 2 + 1
            let rightChildIndex = leftChildIndex + 1
            guard leftChildIndex < entries.count else { break }

            let smallerChildIndex: Int
            if rightChildIndex < entries.count,
               entries[rightChildIndex].distanceFromStartMeters
                < entries[leftChildIndex].distanceFromStartMeters {
                smallerChildIndex = rightChildIndex
            } else {
                smallerChildIndex = leftChildIndex
            }

            guard entries[smallerChildIndex].distanceFromStartMeters
                    < entries[parentIndex].distanceFromStartMeters else {
                break
            }
            entries.swapAt(parentIndex, smallerChildIndex)
            parentIndex = smallerChildIndex
        }

        return minimumEntry
    }
}
