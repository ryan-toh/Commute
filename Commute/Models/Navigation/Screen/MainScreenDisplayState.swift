import Foundation

struct MainScreenDisplayState {
    let map: MapDisplayState
    let controls: RouteState
}

@MainActor
struct MainScreenActions {
    let map: MapActions
    let controls: NavigationControls
}
