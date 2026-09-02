import Foundation

/// A runtime graph assembled from locally stored cycling-path segments.
///
/// Nodes are formed by snapping nearby segment endpoints; source polylines remain
/// the graph's edges so a returned chain preserves the original route geometry.
struct CyclingPathGraph {
    private struct Node {
        let coordinate: LocationCoordinate
    }

    private struct Edge {
        let destinationNodeID: Int
        let coordinates: [LocationCoordinate]
        let lengthMeters: Double
    }

    private var nodes: [Node] = []
    private var edgesByNodeID: [Int: [Edge]] = [:]
    private var nodeIDsByCell: [GraphCell: Set<Int>] = [:]
    private var componentIDByNodeID: [Int: Int] = [:]

    init(segments: [CyclingPathSegment] = []) {
        rebuild(with: segments)
    }

    mutating func rebuild(with segments: [CyclingPathSegment]) {
        nodes.removeAll(keepingCapacity: true)
        edgesByNodeID.removeAll(keepingCapacity: true)
        nodeIDsByCell.removeAll(keepingCapacity: true)
        componentIDByNodeID.removeAll(keepingCapacity: true)

        for segment in segments {
            guard let first = segment.coordinates.first,
                  let last = segment.coordinates.last,
                  segment.coordinates.count >= 2 else { continue }

            let startNodeID = nodeID(for: first)
            let endNodeID = nodeID(for: last)
            guard startNodeID != endNodeID else { continue }

            let lengthMeters = length(of: segment.coordinates)
            guard lengthMeters > 0 else { continue }

            edgesByNodeID[startNodeID, default: []].append(
                Edge(
                    destinationNodeID: endNodeID,
                    coordinates: segment.coordinates,
                    lengthMeters: lengthMeters
                )
            )
            edgesByNodeID[endNodeID, default: []].append(
                Edge(
                    destinationNodeID: startNodeID,
                    coordinates: Array(segment.coordinates.reversed()),
                    lengthMeters: lengthMeters
                )
            )
        }

        rebuildComponents()
    }

    func nodeIDs(near coordinate: LocationCoordinate, within radiusMeters: Double) -> [Int] {
        let identifiers = cells(around: coordinate, radiusMeters: radiusMeters)
            .reduce(into: Set<Int>()) { result, cell in
                result.formUnion(nodeIDsByCell[cell] ?? [])
            }

        return identifiers.filter {
            distance(between: nodes[$0].coordinate, and: coordinate) <= radiusMeters
        }
    }

    func coordinate(for nodeID: Int) -> LocationCoordinate? {
        nodes.indices.contains(nodeID) ? nodes[nodeID].coordinate : nil
    }

    func componentID(for nodeID: Int) -> Int? {
        componentIDByNodeID[nodeID]
    }

    func shortestChain(
        from startNodeID: Int,
        to endNodeID: Int,
        maximumLengthMeters: Double
    ) -> CyclingPathChain? {
        guard nodes.indices.contains(startNodeID),
              nodes.indices.contains(endNodeID),
              startNodeID != endNodeID else { return nil }

        var distanceByNodeID: [Int: Double] = [startNodeID: 0]
        var predecessorByNodeID: [Int: (nodeID: Int, edge: Edge)] = [:]
        var unvisited = MinimumDistanceQueue()
        unvisited.insert(GraphQueueEntry(nodeID: startNodeID, distance: 0))

        while let current = unvisited.removeMinimum() {
            guard current.distance == distanceByNodeID[current.nodeID] else { continue }
            guard current.distance <= maximumLengthMeters else { continue }
            if current.nodeID == endNodeID { break }

            for edge in edgesByNodeID[current.nodeID, default: []] {
                let nextDistance = current.distance + edge.lengthMeters
                guard nextDistance <= maximumLengthMeters,
                      nextDistance < (distanceByNodeID[edge.destinationNodeID] ?? .infinity) else { continue }

                distanceByNodeID[edge.destinationNodeID] = nextDistance
                predecessorByNodeID[edge.destinationNodeID] = (current.nodeID, edge)
                unvisited.insert(GraphQueueEntry(nodeID: edge.destinationNodeID, distance: nextDistance))
            }
        }

        guard let lengthMeters = distanceByNodeID[endNodeID] else { return nil }

        var edges: [Edge] = []
        var currentNodeID = endNodeID
        while currentNodeID != startNodeID {
            guard let predecessor = predecessorByNodeID[currentNodeID] else { return nil }
            edges.append(predecessor.edge)
            currentNodeID = predecessor.nodeID
        }

        let coordinates = edges.reversed().reduce(into: [LocationCoordinate]()) { result, edge in
            for coordinate in edge.coordinates where result.last != coordinate {
                result.append(coordinate)
            }
        }
        guard coordinates.count >= 2 else { return nil }

        return CyclingPathChain(coordinates: coordinates, lengthMeters: lengthMeters)
    }

    private mutating func nodeID(for coordinate: LocationCoordinate) -> Int {
        let candidates = nodeIDs(near: coordinate, within: Preferences.RoutePlanning.cyclingPathEndpointSnapDistanceMeters)
        if let existingNodeID = candidates.min(by: {
            distance(between: nodes[$0].coordinate, and: coordinate) < distance(between: nodes[$1].coordinate, and: coordinate)
        }) {
            return existingNodeID
        }

        let nodeID = nodes.count
        nodes.append(Node(coordinate: coordinate))
        nodeIDsByCell[GraphCell(coordinate: coordinate), default: []].insert(nodeID)
        return nodeID
    }

    private mutating func rebuildComponents() {
        var nextComponentID = 0

        for nodeID in nodes.indices where componentIDByNodeID[nodeID] == nil {
            var pendingNodeIDs = [nodeID]
            componentIDByNodeID[nodeID] = nextComponentID

            while let currentNodeID = pendingNodeIDs.popLast() {
                for edge in edgesByNodeID[currentNodeID, default: []]
                    where componentIDByNodeID[edge.destinationNodeID] == nil {
                    componentIDByNodeID[edge.destinationNodeID] = nextComponentID
                    pendingNodeIDs.append(edge.destinationNodeID)
                }
            }

            nextComponentID += 1
        }
    }

    private func cells(around coordinate: LocationCoordinate, radiusMeters: Double) -> [GraphCell] {
        let latitudeDelta = radiusMeters / Preferences.CyclingPaths.metersPerLatitudeDegree
        let longitudeDelta = radiusMeters / Preferences.CyclingPaths.metersPerLongitudeDegree(at: coordinate.latitude)
        let minimumLatitude = GraphCell.gridValue(for: coordinate.latitude - latitudeDelta)
        let maximumLatitude = GraphCell.gridValue(for: coordinate.latitude + latitudeDelta)
        let minimumLongitude = GraphCell.gridValue(for: coordinate.longitude - longitudeDelta)
        let maximumLongitude = GraphCell.gridValue(for: coordinate.longitude + longitudeDelta)

        return (minimumLatitude...maximumLatitude).flatMap { latitude in
            (minimumLongitude...maximumLongitude).map { longitude in
                GraphCell(latitude: latitude, longitude: longitude)
            }
        }
    }

    private func length(of coordinates: [LocationCoordinate]) -> Double {
        zip(coordinates, coordinates.dropFirst()).reduce(0) {
            $0 + distance(between: $1.0, and: $1.1)
        }
    }

    private func distance(between first: LocationCoordinate, and second: LocationCoordinate) -> Double {
        let latitudeDelta = (second.latitude - first.latitude) * Preferences.CyclingPaths.metersPerLatitudeDegree
        let longitudeDelta = (second.longitude - first.longitude) * Preferences.CyclingPaths.metersPerLongitudeDegree(at: (first.latitude + second.latitude) / 2)
        return hypot(latitudeDelta, longitudeDelta)
    }
}

private struct GraphQueueEntry {
    let nodeID: Int
    let distance: Double
}

private struct MinimumDistanceQueue {
    private var elements: [GraphQueueEntry] = []

    mutating func insert(_ entry: GraphQueueEntry) {
        elements.append(entry)
        var childIndex = elements.count - 1
        while childIndex > 0 {
            let parentIndex = (childIndex - 1) / 2
            guard elements[childIndex].distance < elements[parentIndex].distance else { break }
            elements.swapAt(childIndex, parentIndex)
            childIndex = parentIndex
        }
    }

    mutating func removeMinimum() -> GraphQueueEntry? {
        guard !elements.isEmpty else { return nil }
        if elements.count == 1 { return elements.removeLast() }

        let minimum = elements[0]
        elements[0] = elements.removeLast()
        var parentIndex = 0

        while true {
            let leftChildIndex = parentIndex * 2 + 1
            let rightChildIndex = leftChildIndex + 1
            guard leftChildIndex < elements.count else { break }

            let smallestChildIndex: Int
            if rightChildIndex < elements.count,
               elements[rightChildIndex].distance < elements[leftChildIndex].distance {
                smallestChildIndex = rightChildIndex
            } else {
                smallestChildIndex = leftChildIndex
            }

            guard elements[smallestChildIndex].distance < elements[parentIndex].distance else { break }
            elements.swapAt(parentIndex, smallestChildIndex)
            parentIndex = smallestChildIndex
        }

        return minimum
    }
}

struct CyclingPathChain {
    let coordinates: [LocationCoordinate]
    let lengthMeters: Double
}

private struct GraphCell: Hashable {
    let latitude: Int
    let longitude: Int

    init(latitude: Int, longitude: Int) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(coordinate: LocationCoordinate) {
        latitude = Self.gridValue(for: coordinate.latitude)
        longitude = Self.gridValue(for: coordinate.longitude)
    }

    static func gridValue(for coordinate: Double) -> Int {
        Int(floor(coordinate / Preferences.CyclingPaths.spatialIndexCellSizeDegrees))
    }
}
