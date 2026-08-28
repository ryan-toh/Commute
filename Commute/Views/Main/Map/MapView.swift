import SwiftUI
import MapKit

struct MapView: View {

    @Environment(\.scenePhase) private var scenePhase
    // MARK: - Data In
    @Environment(LocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel

    // MARK: Data owned by Me
    @State private var mapViewModel = MapViewModel()

    private var displayedRoute: Route? {
        routeNavigationViewModel.activeRoute ?? routePlanningViewModel.route
    }

    var body: some View {
        @Bindable var mapViewModel = mapViewModel

        ZStack(alignment: .bottomTrailing) {
            MapReader { mapProxy in
                Map(position: $mapViewModel.cameraPosition) {
                    RouteLine(route: displayedRoute)
                    UserLocationAnnotation(location: userLocationViewModel.currentLocation)
                    DestinationAnnotation(location: routeNavigationViewModel.destination)
                }
                .onTapGesture { tappedPoint in
                    guard let coordinate = mapProxy.convert(tappedPoint, from: .local) else { return }
                    selectDestination(at: coordinate)
                }
            }
            RecenterButton(action: recenterMap)
        }
        .onChange(of: userLocationViewModel.currentLocation?.coordinate, initial: true) { _, coordinate in
            mapViewModel.setInitialCameraPosition(from: coordinate)
        }
        .onAppear { userLocationViewModel.startObserving(using: locationManager) }
        .onDisappear { userLocationViewModel.stopObserving() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            userLocationViewModel.startObserving(using: locationManager)
        }
    }

    private func recenterMap() {
        Task {
            await mapViewModel.recenter(
                on: userLocationViewModel.currentLocation?.coordinate,
                requestingUserLocation: ensureCurrentUserLocation
            )
        }
    }

    private func ensureCurrentUserLocation() async -> LocationCoordinate? {
        await userLocationViewModel.ensureCurrentLocation(using: locationManager)?.coordinate
    }

    private func selectDestination(at coordinate: CLLocationCoordinate2D) {
        let destination = Location(
            id: UUID(),
            coordinate: LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil,
            name: Preferences.NavigationUI.selectedDestinationName,
            source: .mapSelection,
            capturedAt: .now
        )

        routeNavigationViewModel.selectDestination(destination)
        routePlanningViewModel.clearRoute()
    }
}
