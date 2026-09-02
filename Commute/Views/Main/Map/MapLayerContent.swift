import MapKit
import SwiftUI

/// Arranges optional map content in its fixed visual stacking order.
struct MapLayerContent: MapContent {
    let enabledLayers: Set<MapLayer>
    let cyclingPathPolylines: [CyclingPathMapPolyline]
    let route: Route?
    let routeProgress: RouteProgress?
    let destination: Location?
    let userLocation: Location?

    var body: some MapContent {
        if enabledLayers.contains(.cyclingPaths) {
            CyclingPathSegmentsLayer(polylines: cyclingPathPolylines)
        }
        if enabledLayers.contains(.route) {
            RouteLine(route: route, progress: routeProgress)
        }
        if enabledLayers.contains(.destination) {
            DestinationAnnotation(location: destination)
        }
        if enabledLayers.contains(.userLocation) {
            UserLocationAnnotation(location: userLocation)
        }
    }
}
