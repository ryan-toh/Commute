import CoreGraphics
import CoreLocation
import Foundation
import SwiftUI

enum Preferences {
    enum Location {
        static let recenterMapSpan: CLLocationDistance = 800
        static let recenterAnimationDuration: TimeInterval = 0.35
    }

    enum NavigationCamera {
        static let minimumDistanceMeters: CLLocationDistance = 120
        static let maximumDistanceMeters: CLLocationDistance = 1_000
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
        static let routeLineWidth: CGFloat = 8
        static let routeLineOutlineWidth: CGFloat = 12
        static let completedRouteLineColor = Color.gray.opacity(0.7)
        static let completedRouteLineOutlineColor = Color.gray.opacity(0.9)
        static let remainingRouteLineColor = Color.blue
        static let remainingRouteLineOutlineColor = Color(
            red: 0.02,
            green: 0.23,
            blue: 0.78
        )
        static let routeStartSymbol = "figure.outdoor.cycle"
        static let routeEndSymbol = "figure.walk"
        static let routeStartMarkerColor = Color.blue
        static let routeEndMarkerColor = Color.orange
        static let routeEndpointMarkerSize: CGFloat = 32
        static let routeEndpointMarkerBorderColor = Color.white
        static let routeEndpointMarkerBorderWidth: CGFloat = 2
        static let routeEndpointMarkerShadowRadius: CGFloat = 2
        static let routeStartAccessibilityLabel = "Start"
        static let routeEndAccessibilityLabel = "End"
        static let controlsSpacing: CGFloat = 8
        static let routeControlsPadding: CGFloat = 16
        static let recenterButtonSymbolSize: CGFloat = 24
        static let recenterButtonContentPadding: CGFloat = 15
        static let recenterButtonOuterPadding: CGFloat = 16
        static let selectedDestinationName = "Selected Destination"
        static let destinationSelected = "Destination selected"
        static let planRoute = "Get Directions"
        static let planningRoute = "Planning cycling route…"
        static let startNavigation = "Start"
        static let stopNavigation = "Stop"
        static let rerouting = "Finding a safer route…"
        static let arrived = "You have arrived"
        static let remainingDistanceFormat = "%.0f m remaining"
        static let stepDistanceFormat = "%.0f m"
        static let destinationSymbol = "mappin.circle.fill"
        static let destinationSymbolColor = Color.red
        static let recenterSymbol = "location.fill"
        static let arrivedSymbol = "checkmark.circle.fill"
    }

    enum LocationService {
        static let currentLocationName = "Current Location"
        static let locationUnavailableTitle = "Location unavailable"
        static let locationUnavailableMessage = "GPS location is unavailable. Try again later or move to an open area with a clearer view of the sky."
        static let locationAccessDeniedMessage = "Allow location access in Settings to use navigation."
        static let dismissButtonTitle = "OK"
    }

    enum RoutePlanning {
        static let fallbackInstruction = "Continue"
        static let noRouteFoundMessage = "No cycling route is available for this destination."
    }

    enum PlaceDetails {
        static let searchRadiusMeters: CLLocationDistance = 1_000
        static let maximumMapItemDistanceMeters: CLLocationDistance = 50
        static let cardSpacing: CGFloat = 16
        static let headerSpacing: CGFloat = 10
        static let addressLineLimit = 2
        static let actionSpacing: CGFloat = 12
        static let actionCornerRadius: CGFloat = 16
        static let actionVerticalPadding: CGFloat = 12
        static let actionSymbolSize: CGFloat = 32
        static let routeSummarySymbol = "figure.outdoor.cycle"
        static let callSymbol = "phone.fill"
        static let websiteSymbol = "safari.fill"
        static let loadingSymbol = "ellipsis"
        static let closeSymbol = "xmark"
        static let closeAccessibilityLabel = "Dismiss destination"
        static let closeButtonSymbolSize: CGFloat = 22
        static let closeButtonPadding: CGFloat = 15
        static let distanceFormat = "%.1f km"
        static let durationFormat = "%d min"
        static let routeLabel = "Road Bike"
        static let callLabel = "Call"
        static let websiteLabel = "Website"
    }

    enum DestinationSearch {
        static let searchDelayMilliseconds = 300
        static let maximumContentWidth: CGFloat = 640
        static let searchPrompt = "Search for a destination"
        static let noResultsMessage = "No destinations found."
        static let searchErrorMessage = "Unable to search for destinations."
        static let resultsMaximumHeight: CGFloat = 320
        static let containerCornerRadius: CGFloat = 32
        static let overlayPadding: CGFloat = 24
        static let containerPadding: CGFloat = 0
        static let overlaySpacing: CGFloat = 12
        static let contentPadding: CGFloat = 20
        static let contentTopPadding: CGFloat = 0
        static let searchLoadingHeight: CGFloat = 72
        static let searchLoadingIndicatorPadding: CGFloat = 12
        static let searchFieldHorizontalPadding: CGFloat = 20
        static let searchFieldVerticalPadding: CGFloat = 18
        static let resultItemSpacing: CGFloat = 2
        static let resultItemVerticalPadding: CGFloat = 14
        static let resultListSpacing: CGFloat = 0
        static let contentAppearScale: CGFloat = 0.9
        static let contentAppearAnimation = Animation.spring(response: 0.35, dampingFraction: 0.72)
        static let listExpansionAnimation = Animation.spring(response: 0.42, dampingFraction: 0.64)
    }

    enum DestinationSelection {
        static let minimumPressDuration = 0.5
        static let maximumPressDistance: CGFloat = 12
    }

    enum NavigationSession {
        static let offRouteThresholdMeters = 50.0
        static let arrivalThresholdMeters = 30.0
        static let minimumRerouteInterval: TimeInterval = 10
        static let maneuverAdvanceDistanceMeters = 25.0
    }

    enum CyclingNavigation {
        static let panelTransitionAnimation = Animation.easeInOut(duration: 0.25)
        static let maneuverTransitionAnimation = Animation.easeInOut(duration: 0.3)
        static let statusSymbolAppearAnimation = Animation.spring(response: 0.35, dampingFraction: 0.7)
        static let progressAppearAnimation = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let panelCornerRadius: CGFloat = 24
        static let panelSpacing: CGFloat = 20
        static let maneuverSpacing: CGFloat = 8
        static let maneuverSymbolSize: CGFloat = 76
        static let statusSymbolSize: CGFloat = 48
        static let endNavigationVerticalPadding: CGFloat = 12

        static let nextManeuverDistanceFormat = "In %.0f m"
        static let remainingDistanceSymbol = "figure.outdoor.cycle"
        static let planRouteSymbol = "map.fill"
        static let startNavigationSymbol = "figure.outdoor.cycle"
        static let endNavigationSymbol = "stop.circle.fill"
        static let reroutingSymbol = "arrow.triangle.2.circlepath"
        static let failedSymbol = "exclamationmark.triangle.fill"
        static let arrivedSymbol = "checkmark.circle.fill"
        static let navigationFailedMessage = "Navigation is unavailable."

        static let straightSymbol = "arrow.up"
        static let slightLeftSymbol = "arrow.up.left"
        static let leftSymbol = "arrow.turn.up.left"
        static let sharpLeftSymbol = "arrow.down.left"
        static let slightRightSymbol = "arrow.up.right"
        static let rightSymbol = "arrow.turn.up.right"
        static let sharpRightSymbol = "arrow.down.right"
        static let uTurnSymbol = "arrow.uturn.backward"
        static let arriveSymbol = "mappin.and.ellipse"
        static let unknownManeuverSymbol = "arrow.up"
    }

    enum Motion {
        static let overlayTransitionAnimation = Animation.easeInOut(duration: 0.25)
        static let listItemAppearAnimation = Animation.easeOut(duration: 0.2)
        static let buttonPressAnimation = Animation.easeOut(duration: 0.12)
        static let locationHaloPulseAnimation = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
        static let destinationSymbolEffect = SymbolEffectOptions.speed(0.8)
    }
}
