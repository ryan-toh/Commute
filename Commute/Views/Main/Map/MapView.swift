import SwiftUI
import MapKit

struct MapView: View {
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel

    // MARK: - Data In
    let mapViewModel: MapViewModel
    let mapLayerViewModel: MapLayerViewModel
    let mapScope: Namespace.ID
    let onDestinationSelected: (Location) -> Void
    let onDestinationDismissed: () -> Void
    let onVisibleSearchAreaChanged: (PlaceSearchArea) -> Void

    // MARK: - Data In
    private var displayedRoute: Route? {
        routeNavigationViewModel.state.isNavigating
            ? routeNavigationViewModel.activeRoute
            : routePlanningViewModel.route
    }

    // MARK: - Data In
    private var displayedDestination: Location? {
        routeNavigationViewModel.state.isNavigating
            ? routeNavigationViewModel.destination
            : routePlanningViewModel.destination
    }

    var body: some View {
        @Bindable var mapViewModel = mapViewModel

        ZStack(alignment: .bottomTrailing) {
            MapReader { mapProxy in
                Map(
                    position: $mapViewModel.cameraPosition,
                    bounds: navigationCameraBounds,
                    scope: mapScope
                ) {
                    MapLayerContent(
                        enabledLayers: mapLayerViewModel.enabledLayers,
                        cyclingPathPolylines: mapLayerViewModel.loadedCyclingPathPolylines,
                        route: displayedRoute,
                        routeProgress: routeNavigationViewModel.progress,
                        destination: displayedDestination,
                        userLocation: userLocationViewModel.currentLocation
                    )
                }
                .mapStyle(mapLayerViewModel.isSatelliteStyleEnabled ? .imagery : .standard)
                .simultaneousGesture(
                    destinationSelectionGesture(using: mapProxy),
                    including: routeNavigationViewModel.state.isNavigating ? .none : .all
                )
                .onMapCameraChange(frequency: .onEnd) { context in
                    mapViewModel.updateVisibleSearchArea(from: context.region)
                    if let area = mapViewModel.visibleSearchArea {
                        onVisibleSearchAreaChanged(area)
                        mapLayerViewModel.updateVisibleArea(area)
                    }
                }
                .mapControlVisibility(.hidden)
                .animation(
                    reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
                    value: displayedRoute?.id
                )
            }
        }
        .onTapGesture {
            guard !routeNavigationViewModel.state.isNavigating,
                  routePlanningViewModel.destination != nil else { return }
            onDestinationDismissed()
        }
        // set camera position to center on user location
        .onChange(of: userLocationViewModel.currentLocation?.coordinate, initial: true) { _, coordinate in
            mapViewModel.setInitialCameraPosition(from: coordinate)
        }
        .onChange(of: routePlanningViewModel.destination) { _, destination in
            guard destination?.source == .search, let coordinate = destination?.coordinate else { return }
            mapViewModel.recenter(on: coordinate)
        }
    }

    private func destinationSelectionGesture(using mapProxy: MapProxy) -> some Gesture {
        let longPress = LongPressGesture(
            minimumDuration: Preferences.DestinationSelection.minimumPressDuration,
            maximumDistance: Preferences.DestinationSelection.maximumPressDistance
        )
        .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local))
        .onEnded { value in
            guard value.first == true,
                  let drag = value.second,
                  let coordinate = mapProxy.convert(drag.startLocation, from: .local) else { return }

            selectDestination(at: coordinate)
        }

        return longPress
    }

    private var navigationCameraBounds: MapCameraBounds? {
        guard routeNavigationViewModel.state.isNavigating else { return nil }

        return MapCameraBounds(
            minimumDistance: Preferences.NavigationCamera.minimumDistanceMeters,
            maximumDistance: Preferences.NavigationCamera.maximumDistanceMeters
        )
    }

    private func selectDestination(at coordinate: CLLocationCoordinate2D) {
        onDestinationSelected(Location(
            id: UUID(),
            coordinate: LocationCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil,
            name: Preferences.NavigationUI.selectedDestinationName,
            source: .mapSelection,
            capturedAt: .now
        ))
    }
}
