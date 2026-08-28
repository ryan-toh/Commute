import Foundation

struct MapDisplayState {
    let userLocation: Location?
    let route: Route?
    let destination: Location?
}

@MainActor
struct MapActions {
    let selectDestination: (LocationCoordinate) -> Void
    let requestUserLocation: () async -> Void
}
