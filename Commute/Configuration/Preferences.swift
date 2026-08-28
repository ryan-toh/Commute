import CoreGraphics
import CoreLocation
import Foundation

enum Preferences {
    enum Location {
        static let recenterMapSpan: CLLocationDistance = 800
        static let recenterAnimationDuration: TimeInterval = 0.35
    }

    enum UserLocationMarker {
        static let defaultDotSize: CGFloat = 16
        static let haloScale: CGFloat = 2.6
        static let maximumHaloSize: CGFloat = 48
        static let maximumDotSize: CGFloat = 22
    }

    enum NavigationUI {
        static let routeLineWidth: CGFloat = 6
        static let controlsSpacing: CGFloat = 8
        static let destinationPromptHorizontalPadding: CGFloat = 16
        static let destinationPromptVerticalPadding: CGFloat = 10
        static let destinationPromptBottomPadding: CGFloat = 8

        static let selectedDestinationName = "Selected Destination"
        static let destinationPrompt = "Tap the map to choose a destination"
        static let destinationSelected = "Destination selected"
        static let planRoute = "Plan cycling route"
        static let planningRoute = "Planning cycling route…"
        static let startNavigation = "Start navigation"
        static let stopNavigation = "Stop navigation"
        static let rerouting = "Finding a safer route…"
        static let arrived = "You have arrived"
        static let remainingDistanceFormat = "%.0f m remaining"
        static let destinationSymbol = "mappin.circle.fill"
        static let recenterSymbol = "location.fill"
        static let nextStepSymbol = "arrow.turn.up.right"
    }

    enum NavigationSession {
        static let offRouteThresholdMeters = 50.0
        static let arrivalThresholdMeters = 30.0
        static let minimumRerouteInterval: TimeInterval = 10
    }
}
