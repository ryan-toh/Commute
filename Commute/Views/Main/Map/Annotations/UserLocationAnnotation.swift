import SwiftUI
import MapKit

struct UserLocationAnnotation: MapContent {
    let location: Location?
    var body: some MapContent {
        if let location {
            LocationAnnotation(location: location) { UserLocationStyleView() }
        }
    }
}
