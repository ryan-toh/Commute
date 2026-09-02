import Foundation

struct CyclingPathExcursionPair {
    let entryAnchor: CyclingPathExcursionAnchor
    let exitAnchor: CyclingPathExcursionAnchor

    var forwardProgressMeters: Double {
        exitAnchor.baselineProgressMeters - entryAnchor.baselineProgressMeters
    }
}

struct CyclingPathExcursionPairGenerator {
    func pairs(
        from anchors: [CyclingPathExcursionAnchor],
        minimumForwardProgressMeters: Double,
        maximumPairCount: Int
    ) -> [CyclingPathExcursionPair] {
        var pairs: [CyclingPathExcursionPair] = []

        for entryAnchor in anchors {
            for exitAnchor in anchors {
                guard entryAnchor.id != exitAnchor.id,
                      entryAnchor.networkComponentID == exitAnchor.networkComponentID else {
                    continue
                }

                let pair = CyclingPathExcursionPair(
                    entryAnchor: entryAnchor,
                    exitAnchor: exitAnchor
                )
                guard pair.forwardProgressMeters >= minimumForwardProgressMeters else {
                    continue
                }
                pairs.append(pair)
            }
        }

        return Array(
            pairs
                .sorted { first, second in
                    first.forwardProgressMeters > second.forwardProgressMeters
                }
                .prefix(maximumPairCount)
        )
    }
}
