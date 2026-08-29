import MapKit
import Observation
import SwiftUI

/// Owns mutable camera state and camera movements for a single navigation map.
@MainActor
@Observable
final class MapViewModel {
    var cameraPosition: MapCameraPosition = .automatic
    private(set) var visibleSearchArea: LocationSearchArea?

    private var hasCenteredOnInitialLocation = false

    func setInitialCameraPosition(from coordinate: LocationCoordinate?) {
        guard !hasCenteredOnInitialLocation, let coordinate else { return }

        hasCenteredOnInitialLocation = true
        updateCameraPosition(for: coordinate)
    }

    func recenter(on coordinate: LocationCoordinate) {
        updateCameraPosition(for: coordinate)
    }

    func followUserHeading(from fallbackCoordinate: LocationCoordinate) {
        withAnimation(.easeInOut(duration: Preferences.Location.recenterAnimationDuration)) {
            cameraPosition = .userLocation(
                followsHeading: true,
                fallback: .region(region(centeredOn: fallbackCoordinate))
            )
        }
    }

    func updateVisibleSearchArea(from region: MKCoordinateRegion) {
        visibleSearchArea = LocationSearchArea(
            center: LocationCoordinate(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            ),
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta
        )
    }

    private func updateCameraPosition(for coordinate: LocationCoordinate) {
        withAnimation(.easeInOut(duration: Preferences.Location.recenterAnimationDuration)) {
            cameraPosition = .region(region(centeredOn: coordinate))
        }
    }

    private func region(centeredOn coordinate: LocationCoordinate) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            latitudinalMeters: Preferences.Location.recenterMapSpan,
            longitudinalMeters: Preferences.Location.recenterMapSpan
        )
    }
}
