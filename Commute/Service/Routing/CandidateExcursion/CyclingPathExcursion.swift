import Foundation

struct CyclingPathExcursion {
    let identifier: String
    let entryAnchor: CyclingPathExcursionAnchor
    let exitAnchor: CyclingPathExcursionAnchor
    let networkRoute: CyclingPathNetworkRoute

    var entryCoordinate: LocationCoordinate {
        entryAnchor.cyclingPathProjection.coordinate
    }

    var exitCoordinate: LocationCoordinate {
        exitAnchor.cyclingPathProjection.coordinate
    }

    var forwardBaselineProgressMeters: Double {
        exitAnchor.baselineProgressMeters - entryAnchor.baselineProgressMeters
    }
}

enum CyclingPathExcursionRejectionReason: Equatable {
    case insufficientCyclingPathDistance
    case insufficientForwardProgress
    case insufficientDestinationProgress
    case excessiveLocalDetour
}

struct CyclingPathExcursionFilter {
    private let geometry = CyclingPathGeometry()

    func rejectionReason(
        for excursion: CyclingPathExcursion,
        destinationCoordinate: LocationCoordinate,
        minimumCyclingPathDistanceMeters: Double,
        minimumForwardProgressMeters: Double,
        minimumDestinationProgressMeters: Double,
        maximumDistanceToBaselineProgressRatio: Double
    ) -> CyclingPathExcursionRejectionReason? {
        guard excursion.networkRoute.cyclingPathDistanceMeters
                >= minimumCyclingPathDistanceMeters else {
            return .insufficientCyclingPathDistance
        }
        guard excursion.forwardBaselineProgressMeters >= minimumForwardProgressMeters else {
            return .insufficientForwardProgress
        }

        let entryDistanceToDestinationMeters = geometry.distance(
            from: excursion.entryCoordinate,
            to: destinationCoordinate
        )
        let exitDistanceToDestinationMeters = geometry.distance(
            from: excursion.exitCoordinate,
            to: destinationCoordinate
        )
        let destinationProgressMeters = entryDistanceToDestinationMeters
            - exitDistanceToDestinationMeters
        guard destinationProgressMeters >= minimumDestinationProgressMeters else {
            return .insufficientDestinationProgress
        }

        let maximumExcursionDistanceMeters = excursion.forwardBaselineProgressMeters
            * maximumDistanceToBaselineProgressRatio
        guard excursion.networkRoute.totalDistanceMeters <= maximumExcursionDistanceMeters else {
            return .excessiveLocalDetour
        }

        return nil
    }
}
