import SwiftUI
import MapKit

struct RouteLine: MapContent {
    let route: Route?
    var body: some MapContent {
        if let route {
            MapPolyline(coordinates: route.coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                .stroke(.blue, lineWidth: Preferences.NavigationUI.routeLineWidth)
        }
    }
}
