import Foundation
import Testing
@testable import Commute

struct CyclingPathExcursionAnchorTests {
    @Test func pairGeneratorRequiresForwardProgressWithinOneComponent() {
        let edgeID = CyclingPathNetwork.EdgeID(rawValue: 1)
        let entry = makeAnchor(id: 1, edgeID: edgeID, progress: 100, componentID: 3)
        let usefulExit = makeAnchor(id: 2, edgeID: edgeID, progress: 400, componentID: 3)
        let backwardsExit = makeAnchor(id: 3, edgeID: edgeID, progress: 50, componentID: 3)
        let disconnectedExit = makeAnchor(id: 4, edgeID: edgeID, progress: 500, componentID: 4)

        let pairs = CyclingPathExcursionPairGenerator().pairs(
            from: [entry, usefulExit, backwardsExit, disconnectedExit],
            minimumForwardProgressMeters: 100,
            maximumPairCount: 10
        )

        #expect(pairs.contains {
            $0.entryAnchor.id == entry.id && $0.exitAnchor.id == usefulExit.id
        })
        #expect(pairs.contains {
            $0.entryAnchor.id == entry.id && $0.exitAnchor.id == backwardsExit.id
        } == false)
        #expect(pairs.contains {
            $0.entryAnchor.id == entry.id && $0.exitAnchor.id == disconnectedExit.id
        } == false)
    }

    private func makeAnchor(
        id: Int,
        edgeID: CyclingPathNetwork.EdgeID,
        progress: Double,
        componentID: Int
    ) -> CyclingPathExcursionAnchor {
        CyclingPathExcursionAnchor(
            id: .init(rawValue: id),
            cyclingPathProjection: CyclingPathProjection(
                edgeID: edgeID,
                coordinate: LocationCoordinate(latitude: 1, longitude: 103),
                fractionAlongEdge: 0.5,
                distanceFromQueryMeters: 5,
                distanceFromEdgeStartMeters: 10
            ),
            baselineProgressMeters: progress,
            networkComponentID: componentID
        )
    }
}
