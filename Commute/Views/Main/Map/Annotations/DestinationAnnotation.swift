import SwiftUI
import MapKit

struct DestinationAnnotation: MapContent {
    let location: Location?
    var body: some MapContent {
        if let location {
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)) {
                Image(systemName: Preferences.NavigationUI.destinationSymbol).font(.title).foregroundStyle(.red)
            }
        }
    }
}
