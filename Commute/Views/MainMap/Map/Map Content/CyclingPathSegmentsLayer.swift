import MapKit
import SwiftUI

/// Draws the cycling paths selected for the visible map area.
struct CyclingPathSegmentsLayer: MapContent {
    let polylines: [CyclingPathMapPolyline]

    var body: some MapContent {
        ForEach(polylines) { path in
            MapPolyline(path.polyline)
                .stroke(
                    Preferences.MapLayers.cyclingPathLineColor,
                    lineWidth: Preferences.MapLayers.cyclingPathLineWidth
                )
        }
    }

}
