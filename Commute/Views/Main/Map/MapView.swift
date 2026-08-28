import SwiftUI
import MapKit

struct MapView: View {

    // MARK: Data In
    let userLocation: Location?
    let route: Route?
    let destination: Location?
    let requestingUserLocation: () async -> Void
    let onMapTap: (LocationCoordinate) -> Void

    // MARK: Data owned by Me
    @State private var mapViewModel = MapViewModel()

    var body: some View {
        @Bindable var mapViewModel = mapViewModel

        ZStack(alignment: .bottomTrailing) {
            MapReader { mapProxy in
                Map(position: $mapViewModel.cameraPosition) {
                    RouteLine(route: route)
                    UserLocationAnnotation(location: userLocation)
                    DestinationAnnotation(location: destination)
                }
                .onTapGesture { tappedPoint in
                    guard let coordinate = mapProxy.convert(tappedPoint, from: .local) else { return }
                    onMapTap(LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
                }
            }
            RecenterButton(action: recenterMap)
        }
        .onChange(of: userLocation?.coordinate) { _, coordinate in
            mapViewModel.setInitialCameraPosition(from: coordinate)
        }
    }

    private func recenterMap() {
        Task {
            await mapViewModel.recenter(
                on: userLocation?.coordinate,
                requestingUserLocation: requestingUserLocation
            )
        }
    }
}
