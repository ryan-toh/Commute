import Foundation

enum UserRouteState: Equatable {
    case idle
    case following
    case rerouting
    case arrived
    case stopped
    case failed
}
