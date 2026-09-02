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

    enum CyclingPaths {
        enum CloudflareDownloadError {
            static let invalidResponseMessage = "The cycling path service returned an invalid response."
            static let snapshotNotFoundMessage = "The cycling path service does not have a published snapshot."
            static let invalidPayloadMessage = "The cycling path service returned an invalid segment payload."
        }

        enum DownloadBackend: Sendable {
            case dataGovSG
            case cloudflareR2(URL)
            case allSources
        }

        nonisolated static let sourceID = "data.gov.sg.cycling-path-network.v3"
        nonisolated static let cloudflareR2SourceID = "cloudflare-r2.cycling-path-network.v1"
        nonisolated static let allSourcesSourceID = "composite.cycling-path-network.v1"
        nonisolated static let cloudflareR2Endpoint = URL(string: "https://commute-cycling-path-segment.ryandev-devprod.workers.dev/v1/cycling-path-segments")!
        nonisolated static let downloadBackend: DownloadBackend = .allSources
        nonisolated static let dataGovSGSources = [
            DataGovSGSource(
                id: "data.gov.sg.d_8f468b25193f64be8a16fa7d8f60f553",
                pollDownloadEndpoint: URL(string: "https://api-open.data.gov.sg/v1/public/api/datasets/d_8f468b25193f64be8a16fa7d8f60f553/poll-download")!
            ),
            DataGovSGSource(
                id: "data.gov.sg.d_a69ef89737379f231d2ae93fd1c5707f",
                pollDownloadEndpoint: URL(string: "https://api-open.data.gov.sg/v1/public/api/datasets/d_a69ef89737379f231d2ae93fd1c5707f/poll-download")!
            )
        ]
        nonisolated static let minimumRefreshInterval: TimeInterval = 24 * 60 * 60
        nonisolated static let spatialIndexCellSizeDegrees = 0.01
        nonisolated static let metersPerLatitudeDegree = 111_132.0

        nonisolated static func metersPerLongitudeDegree(at latitude: Double) -> Double {
            111_320.0 * cos(latitude * .pi / 180)
        }
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

    enum MainLayout {
        static let searchTopPadding: CGFloat = 8
        static let compactHeightThreshold: CGFloat = 500
        static let compactSearchResultsMaximumHeight: CGFloat = 160
        static let regularSearchResultsMaximumHeight: CGFloat = 320
        static let regularWidthRoutePanelMaximumWidth: CGFloat = 640
        static let routePanelHorizontalMargin: CGFloat = 32
    }

    enum MapLayers {
        static let pickerSymbol = "square.3.layers.3d"
        static let pickerSymbolSize: CGFloat = 20
        static let pickerAccessibilityLabel = "Map layers"
        static let pickerExpansionAccessibilityHint = "Shows the available map layers"
        static let pickerCollapseAccessibilityHint = "Hides the available map layers"
        static let layerShownAccessibilityValue = "Shown"
        static let layerHiddenAccessibilityValue = "Hidden"
        static let layerShowAccessibilityHint = "Double tap to show"
        static let layerHideAccessibilityHint = "Double tap to hide"
        static let pickerArcOffsets: [CGSize] = [
            CGSize(width: 0, height: -80),
            CGSize(width: -50, height: -50),
            CGSize(width: -80, height: 0)
        ]
        static let pickerLayerSymbolSize: CGFloat = 17
        static let satelliteSymbol = "globe.americas.fill"
        static let standardMapSymbol = "map.fill"
        static let satelliteAccessibilityLabel = "Satellite map"
        static let standardMapAccessibilityLabel = "Standard map"
        static let satelliteEnableAccessibilityHint = "Double tap to switch to satellite imagery"
        static let satelliteDisableAccessibilityHint = "Double tap to switch to the standard map"
        static let pickerLayerControlSize: CGFloat = 54
        static let pickerCollapsedScale: CGFloat = 0.18
        static let pickerLayerAnimation = Animation.bouncy(duration: 0.32, extraBounce: 0.12)
        static let cyclingPathLineColor = Color.green.opacity(0.8)
        static let cyclingPathLineWidth: CGFloat = 4
        static let maximumCyclingPathLayerLatitudeDelta = 0.06
        static let maximumCyclingPathLayerLongitudeDelta = 0.06
        static let maximumRenderedCyclingPathSegments = 180
        static let maximumRenderedPointsPerCyclingPath = 40
        static let cyclingPathPolylineCacheLimit = 1_000
        static let cyclingPathLayerRetainedAreaPaddingFactor = 1.5

        static func title(for layer: MapLayer) -> String {
            switch layer {
            case .cyclingPaths: "Cycling paths"
            case .route: "Route"
            case .destination: "Destination"
            case .userLocation: "My location"
            }
        }

        static func symbol(for layer: MapLayer) -> String {
            switch layer {
            case .cyclingPaths: "bicycle"
            case .route: "point.topleft.down.to.point.bottomright.curvepath"
            case .destination: "mappin"
            case .userLocation: "location"
            }
        }
    }

    enum LocationService {
        static let currentLocationName = "Current Location"
        static let locationUnavailableTitle = "Location unavailable"
        static let locationUnavailableMessage = "GPS location is unavailable. Try again later or move to an open area with a clearer view of the sky."
        static let locationAccessDeniedMessage = "Allow location access in Settings to use navigation."
        static let dismissButtonTitle = "OK"
    }

    enum RoutePlanning {
        enum Service {
            case mapKit
            case cyclingPathAware
        }

        static let selectedService: Service = .cyclingPathAware
        static let fallbackInstruction = "Continue"
        static let noRouteFoundMessage = "No cycling route is available for this destination."
        static let cyclingPathSearchRadiusMeters = 250.0
        static let destinationFallbackSearchRadiusMeters = 250.0
        static let maximumDestinationFallbackTargets = 3
        static let nearbyCyclingPathDestinationName = "Nearby cycling path"
        static let nearbyDestinationArrivalInstruction = "Arrive near the destination"
        static let maximumCandidateExcursions = 8
        static let maximumCyclingPathProjectionsPerBaselineCoordinate = 2
        static let maximumCandidateExcursionAnchors = 24
        static let maximumCandidateExcursionAnchorPairs = 12
        static let maximumCyclingPathNetworkConnectionDistanceMeters = 12.0
        static let maximumCandidateExcursionNetworkDistanceMeters = 5_000.0
        static let minimumCyclingPathForwardProgressMeters = 20.0
        static let minimumDestinationProgressMeters = 50.0
        static let maximumExcursionDistanceToBaselineProgressRatio = 1.5
        static let minimumCandidateExcursionCyclingPathDistanceMeters = 100.0
        /// The largest acceptable increase over the direct route's travel time.
        static let maximumAddedTravelTimePercentage = 0.15
        static let assumedCyclingPathSpeedMetersPerSecond = 5.0
        static let cyclingPathInstruction = "Follow the cycling path"
        static let cyclingPathEntryName = "Cycling path entry"
        static let cyclingPathExitName = "Cycling path exit"
        static let forceAllNearbyCyclingPathsForDevelopment = false
    }

    enum DevTools {
        static let routeComparisonTitle = "Route comparison"
        static let compareRoutesTitle = "Compare routes"
        static let routesSectionTitle = "Routes"
        static let cyclingPathDatabaseSectionTitle = "Cycling path database"
        static let repositoryPreparedLabel = "Repository prepared"
        static let preparationErrorLabel = "Preparation error"
        static let retrySyncTitle = "Retry sync"
        static let yesLabel = "Yes"
        static let noLabel = "No"
        static let storedSegmentCountLabel = "Stored segments"
        static let indexedCandidateCountLabel = "Indexed candidates along MapKit route"
        static let routeDecisionSectionTitle = "Cycling-path route decision"
        static let excursionAnchorCountLabel = "Candidate entry and exit points"
        static let compatibleAnchorPairCountLabel = "Compatible entry–exit pairs"
        static let candidateExcursionCountLabel = "Candidate excursions"
        static let viableCandidateCountLabel = "Candidates within time limit"
        static let selectedCandidateLabel = "Selected candidate"
        static let directRouteSelectionLabel = "Direct MapKit route"
        static let candidateDecisionsSectionTitle = "Candidate decisions"
        static let noCandidateDecisionsLabel = "No candidates were eligible for connector routing."
        static let candidateExcursionLabel = "Cycling-path excursion"
        static let connectorRouteUnavailableLabel = "Rejected: MapKit could not route a connector"
        static let invalidCandidateConfigurationLabel = "Rejected: invalid routing configuration"
        static let exceededTimePenaltyFormat = "Rejected: added %d min exceeds the time limit"
        static let viableCandidateLabel = "Viable"
        static let selectedCandidateOutcomeLabel = "Selected"
        static let cyclingPathDistanceFormat = "%d m of cycling path"
        static let sampleSegmentsSectionTitle = "Stored segment samples"
        static let unnamedSegmentLabel = "Unnamed cycling path"
        static let coordinateCountFormat = "%d coordinates"
        static let sampleSegmentLimit = 3
        static let inspectorHeight: CGFloat = 300
        static let mapKitRouteLabel = "MapKit"
        static let cyclingPathRouteLabel = "Cycling-path aware"
        static let originLabel = "Origin"
        static let destinationLabel = "Destination"
        static let routeNotPlannedLabel = "Not planned"
        static let routeDistanceFormat = "%d m"
        static let routeDurationFormat = "%d min"
        static let mapKitRouteColor = Color.orange
        static let cyclingPathRouteColor = Color.cyan
        static let routeLineWidth: CGFloat = 7
        static let routeCameraPaddingFactor = 1.25
        static let debugButtonSymbol = "arrow.triangle.branch"
        static let debugButtonPadding: CGFloat = 14
        static let developerToolsTitle = "Developer tools"
        static let routeEditorTitle = "Cycling path editor"
        static let openRouteComparisonTitle = "Compare routes"
        static let openCyclingPathEditorTitle = "Draw and upload path"
        static let routeEditorSymbol = "point.topleft.down.to.point.bottomright.curvepath"
        static let routeEditorInstructions = "Tap the map to draw the cycling path. Add at least two points, then upload it to the development service."
        static let routeEditorNamePrompt = "Path name (optional)"
        static let routeEditorSecretPrompt = "Upload secret"
        static let routeEditorPublishTitle = "Publish snapshot after upload"
        static let routeEditorUndoTitle = "Undo point"
        static let routeEditorClearTitle = "Clear path"
        static let routeEditorUploadTitle = "Upload segment"
        static let routeEditorUploadingTitle = "Uploading…"
        static let routeEditorPointCountFormat = "%d points"
        static let routeEditorMinimumPointMessage = "Add at least two points before uploading."
        static let routeEditorMissingSecretMessage = "Enter the upload secret before uploading."
        static let routeEditorUploadSucceededMessage = "Cycling path segment uploaded."
        static let routeEditorUploadFailedMessage = "The cycling path segment could not be uploaded."
        static let routeEditorFetchDatabaseTitle = "Fetch latest combined database"
        static let routeEditorFetchingDatabaseTitle = "Fetching latest database…"
        static let routeEditorFetchDatabaseSucceededMessage = "The local cycling-path database is up to date."
        static let routeEditorFetchDatabaseFailedMessage = "The latest cycling-path database could not be fetched."
        static let routeEditorFetchDatabaseInProgressMessage = "A cycling-path database refresh is already in progress."
        static let routeEditorDeleteDatabaseTitle = "Delete local cycling-path database"
        static let routeEditorDeleteDatabaseConfirmationTitle = "Delete local cycling-path data?"
        static let routeEditorDeleteDatabaseConfirmationMessage = "This removes the downloaded cycling-path segments from this device. You can fetch a fresh combined database afterwards."
        static let routeEditorDeleteDatabaseActionTitle = "Delete database"
        static let routeEditorDeleteDatabaseSucceededMessage = "The local cycling-path database was deleted."
        static let routeEditorDeleteDatabaseInProgressMessage = "A cycling-path database operation is already in progress."
        static let routeEditorMapLineColor = Color.cyan
        static let routeEditorMapLineWidth: CGFloat = 7
        static let routeEditorInitialLatitude = 1.3521
        static let routeEditorInitialLongitude = 103.8198
        static let routeEditorInitialLatitudeDelta = 0.04
        static let routeEditorInitialLongitudeDelta = 0.04
        static let routeEditorSheetHeight: CGFloat = 620
    }

    enum PlaceDetail {
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
        static let nearbyDestinationFormat = "%d m from destination"
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
