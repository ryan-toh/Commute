import MapKit
import SwiftUI
import SwiftData

/// Presents the complete navigation experience: map first, controls second.
struct MainView: View {
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(MainViewModel.self) private var mainViewModel
    
    // MARK: - Data owned by Me
    @State private var mapViewModel = MapViewModel()
    
    // MARK: - Data owned by Me
    #if DEBUG
    @State private var isShowingRouteComparison = false
    @State private var isShowingCyclingPathEditor = false
    @State private var isShowingUIKitTest = false
    #endif
    @FocusState private var isSearchFocused: Bool
    
    
    @Namespace private var mapScope

    var body: some View {
        let userLocationViewModel = mainViewModel.userLocationViewModel
        let destinationSearchViewModel = mainViewModel.destinationSearchViewModel
        let cyclingPathRepository = mainViewModel.cyclingPathRepository
        let mapLayerViewModel = mainViewModel.mapLayerViewModel
        let routePlanningViewModel = mainViewModel.routePlanningViewModel
        let routeNavigationViewModel = mainViewModel.routeNavigationViewModel

        ZStack {
            MapView(
                mapViewModel: mapViewModel,
                mapLayerViewModel: mapLayerViewModel,
                mapScope: mapScope,
                onDestinationSelected: mainViewModel.selectDestination,
                onDestinationDismissed: mainViewModel.dismissDestination,
                onVisibleSearchAreaChanged: mainViewModel.updateVisibleSearchArea
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                if !routeNavigationViewModel.currentState.isNavigating {
                    DestinationSearchView(
                        viewModel: destinationSearchViewModel,
                        isSearchFocused: $isSearchFocused,
                        onDestinationSelected: mainViewModel.selectDestination
                    )
                    .padding(.top, Preferences.MainLayout.searchTopPadding)
                    .transition(.opacity)
                    .layoutPriority(0)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 0) {
                    Group {
                        MapLayerButton(
                            enabledLayers: mapLayerViewModel.enabledLayers,
                            isSatelliteStyleEnabled: mapLayerViewModel.isSatelliteStyleEnabled,
                            onLayerEnabledChanged: { layer, isEnabled in
                                mapLayerViewModel.setLayer(layer, isEnabled: isEnabled)
                                mainViewModel.updateCyclingPathLayer(
                                    for: mapViewModel.visibleSearchArea
                                )
                            },
                            onSatelliteStyleEnabledChanged: { isEnabled in
                                mapLayerViewModel.setSatelliteStyle(isEnabled: isEnabled)
                            }
                        )
                        HStack(spacing: 0) {
                            if routeNavigationViewModel.currentState.isNavigating {
                                MapCompass(scope: mapScope)
                                    .controlSize(.large)
                            }
                            Spacer()
                            RecenterButton {
                                mainViewModel.recenterMap(using: mapViewModel)
                            }
                        }

                    }
                    .padding(.trailing, Preferences.NavigationUI.recenterButtonOuterPadding)
                    .padding(.bottom, Preferences.NavigationUI.recenterButtonOuterPadding)
                    .padding(.leading,
                        Preferences.NavigationUI.recenterButtonOuterPadding)

                    if !isSearchFocused {
                        HStack {
                            Spacer(minLength: 0)
                            ControlView(
                                routePlanningViewModel: routePlanningViewModel,
                                routeNavigationViewModel: routeNavigationViewModel,
                                onPlanRoute: mainViewModel.planRoute,
                                onStartNavigation: {
                                    mainViewModel.startNavigation(using: mapViewModel)
                                },
                                onDestinationDismissed: mainViewModel.dismissDestination
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .transition(.opacity)
                    }
                }

                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            #if DEBUG
            VStack {
                Spacer()
                HStack {
                    Menu {
                        Button(Preferences.DevTools.openCyclingPathEditorTitle) {
                            isShowingCyclingPathEditor = true
                        }

                        Button(Preferences.DevTools.openUIKitTestTitle) {
                            isShowingUIKitTest = true
                        }

                        if userLocationViewModel.currentLocation != nil,
                           routePlanningViewModel.destination != nil,
                           !routeNavigationViewModel.currentState.isNavigating {
                            Button(Preferences.DevTools.openRouteComparisonTitle) {
                                isShowingRouteComparison = true
                            }
                        }
                    } label: {
                        Image(systemName: Preferences.DevTools.debugButtonSymbol)
                            .padding(Preferences.DevTools.debugButtonPadding)
                    }
                    .accessibilityLabel(Preferences.DevTools.developerToolsTitle)
                    .liquidGlassSurface(in: Circle())
                    Spacer()
                }
                .padding()
            }
            #endif
        }
        .mapScope(mapScope)
        .onAppear {
            mainViewModel.startObservingUserLocation()
        }
        .task {
            await mainViewModel.prepareCyclingPathData(
                visibleSearchArea: mapViewModel.visibleSearchArea
            )
        }
        .onDisappear {
            mainViewModel.stopObservingUserLocation()
        }
        .onChange(of: scenePhase) { _, phase in
            mainViewModel.handleScenePhaseChange(phase)
        }
        .onChange(of: cyclingPathRepository.isPrepared) { _, isPrepared in
            guard isPrepared else { return }
            mainViewModel.updateCyclingPathLayer(for: mapViewModel.visibleSearchArea)
        }
        .onChange(of: cyclingPathRepository.contentRevision) { _, _ in
            mainViewModel.updateCyclingPathLayer(for: mapViewModel.visibleSearchArea)
        }
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routeNavigationViewModel.currentState.isNavigating
        )
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: isSearchFocused
        )
        .alert(
            Preferences.LocationService.locationUnavailableTitle,
            isPresented: Binding(
                get: { mainViewModel.isShowingLocationError },
                set: { isShowingLocationError in
                    if !isShowingLocationError {
                        mainViewModel.dismissLocationError()
                    }
                }
            )
        ) {
            Button(Preferences.LocationService.dismissButtonTitle, role: .cancel) {
                mainViewModel.dismissLocationError()
            }
        } message: {
            Text(userLocationViewModel.locationError?.localizedDescription ?? Preferences.LocationService.locationUnavailableMessage)
        }
        #if DEBUG
        .sheet(isPresented: $isShowingRouteComparison) {
            if let origin = userLocationViewModel.currentLocation,
               let destination = routePlanningViewModel.destination {
                RouteComparisonView(
                    origin: origin,
                    destination: destination,
                    cyclingPathRepository: cyclingPathRepository
                )
            }
        }
        .sheet(isPresented: $isShowingCyclingPathEditor) {
            CyclingPathSegmentEditorView()
        }
        .sheet(isPresented: $isShowingUIKitTest) {
            TestView()
        }
        #endif
    }

}

private struct PreviewCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    func downloadSegments(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> [CyclingPathSegment] { [] }
}

#Preview {
    let locationManager = UserLocationManager()
    let userLocationViewModel = UserLocationViewModel()
    let destinationSearchViewModel = DestinationSearchViewModel(
        destinationSearchService: MapKitDestinationSearchService()
    )
    let cyclingPathModelContainer = try! ModelContainer(
        for: CyclingPathSegmentRecord.self,
        CyclingPathSyncMetadataRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let cyclingPathRepository = CyclingPathRepository(
        downloader: PreviewCyclingPathSegmentDownloader(),
        store: SwiftDataCyclingPathSegmentStore(
            modelContext: ModelContext(cyclingPathModelContainer)
        )
    )
    let mapLayerViewModel = MapLayerViewModel(
        cyclingPathRepository: cyclingPathRepository
    )
    let routePlanningService = RoutePlanningServiceFactory.make(
        using: cyclingPathRepository
    )
    let navigationRouteViewModel = RoutePlanningViewModel(
        routePlanningService: routePlanningService,
        placeDetailsService: MapKitPlaceDetailsService()
    )
    let navigationSessionViewModel = RouteNavigationViewModel(
        routePlanningService: routePlanningService,
        routeProgressCalculator: RouteProgressCalculator()
    )
    let mainViewModel = MainViewModel(
        locationManager: locationManager,
        userLocationViewModel: userLocationViewModel,
        destinationSearchViewModel: destinationSearchViewModel,
        cyclingPathRepository: cyclingPathRepository,
        mapLayerViewModel: mapLayerViewModel,
        routePlanningViewModel: navigationRouteViewModel,
        routeNavigationViewModel: navigationSessionViewModel
    )
    
    MainView()
        .environment(locationManager)
        .environment(userLocationViewModel)
        .environment(destinationSearchViewModel)
        .environment(cyclingPathRepository)
        .environment(mapLayerViewModel)
        .environment(navigationRouteViewModel)
        .environment(navigationSessionViewModel)
        .environment(mainViewModel)
}
