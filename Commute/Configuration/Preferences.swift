import CoreGraphics
import CoreLocation
import Foundation
import SwiftUI

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
        static let haloColor = Color.blue.opacity(0.18)
        static let dotColor = Color.blue
        static let borderColor = Color.white
        static let borderWidth: CGFloat = 3
        static let shadowColor = Color.black.opacity(0.25)
        static let shadowRadius: CGFloat = 2
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
        static let stepDistanceFormat = "%.0f m"
        static let destinationSymbol = "mappin.circle.fill"
        static let recenterSymbol = "location.fill"
        static let nextStepSymbol = "arrow.turn.up.right"
        static let arrivedSymbol = "checkmark.circle.fill"
    }

    enum LocationService {
        static let currentLocationName = "Current Location"
        static let locationUnavailableMessage = "Your current location is unavailable."
        static let locationAccessDeniedMessage = "Allow location access to plan a route."
    }

    enum RoutePlanning {
        static let fallbackInstruction = "Continue"
        static let noRouteFoundMessage = "No cycling route is available for this destination."
    }

    enum NavigationSession {
        static let offRouteThresholdMeters = 50.0
        static let arrivalThresholdMeters = 30.0
        static let minimumRerouteInterval: TimeInterval = 10
    }
}
