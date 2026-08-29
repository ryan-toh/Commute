import Foundation

enum UserRouteState: Equatable {
    case idle
    case following
    case rerouting
    case arrived
    case stopped
    case failed

    var isNavigating: Bool {
        self == .following || self == .rerouting
    }
}
