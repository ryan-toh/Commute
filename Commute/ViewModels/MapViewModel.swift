import MapKit
import Observation
import SwiftUI

/// Owns mutable camera state and camera movements for a single navigation map.
@MainActor
@Observable
final class MapViewModel {
    var cameraPosition: MapCameraPosition = .automatic

    private var hasCenteredOnInitialLocation = false

    func setInitialCameraPosition(from coordinate: LocationCoordinate?) {
        guard !hasCenteredOnInitialLocation, let coordinate else { return }

        hasCenteredOnInitialLocation = true
        recenter(on: coordinate)
    }

    func recenter(
        on coordinate: LocationCoordinate?,
        requestingUserLocation: () async -> Void
    ) async {
        guard let coordinate else {
            await requestingUserLocation()
            return
        }

        recenter(on: coordinate)
    }

    private func recenter(on coordinate: LocationCoordinate) {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            latitudinalMeters: Preferences.Location.recenterMapSpan,
            longitudinalMeters: Preferences.Location.recenterMapSpan
        )

        withAnimation(.easeInOut(duration: Preferences.Location.recenterAnimationDuration)) {
            cameraPosition = .region(region)
        }
    }
}
