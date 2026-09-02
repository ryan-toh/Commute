import MapKit
import SwiftUI
import SwiftData

/// Presents the complete navigation experience: map first, controls second.
struct MainView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(UserLocationManager.self) private var locationManager
    @Environment(UserLocationViewModel.self) private var userLocationViewModel
    @Environment(DestinationSearchViewModel.self) private var destinationSearchViewModel
    @Environment(CyclingPathRepository.self) private var cyclingPathRepository
    @Environment(MapLayerViewModel.self) private var mapLayerViewModel
    @Environment(RoutePlanningViewModel.self) private var routePlanningViewModel
    @Environment(RouteNavigationViewModel.self) private var routeNavigationViewModel
    
    @State private var mapViewModel = MapViewModel()
    @State private var isShowingLocationError = false
    #if DEBUG
    @State private var isShowingRouteComparison = false
    @State private var isShowingCyclingPathEditor = false
    #endif
    @FocusState private var isSearchFocused: Bool
    @Namespace private var mapScope

    var body: some View {
        GeometryReader { proxy in
            let layout = MainViewLayout(
                size: proxy.size,
                horizontalSizeClass: horizontalSizeClass
            )

            ZStack {
                MapView(
                    mapViewModel: mapViewModel,
                    mapLayerViewModel: mapLayerViewModel,
                    mapScope: mapScope,
                    onDestinationSelected: selectDestination,
                    onDestinationDismissed: dismissDestination,
                    onVisibleSearchAreaChanged: destinationSearchViewModel.updateSearchArea
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                if !routeNavigationViewModel.state.isNavigating {
                    DestinationSearchView(
                        viewModel: destinationSearchViewModel,
                        isSearchFocused: $isSearchFocused,
                        maximumResultsHeight: layout.maximumSearchResultsHeight,
                        onDestinationSelected: selectDestination
                    )
                    .padding(.top, Preferences.MainLayout.searchTopPadding)
                    .transition(.opacity)
                    .layoutPriority(0)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 0) {
                    Group {
                        if layout.showsLayerPicker || routePlanningViewModel.destination == nil {
                            MapLayerPickerView(
                                enabledLayers: mapLayerViewModel.enabledLayers,
                                isSatelliteStyleEnabled: mapLayerViewModel.isSatelliteStyleEnabled,
                                onLayerEnabledChanged: { layer, isEnabled in
                                    mapLayerViewModel.setLayer(layer, isEnabled: isEnabled)
                                    if let area = mapViewModel.visibleSearchArea {
                                        mapLayerViewModel.updateVisibleArea(area)
                                    }
                                },
                                onSatelliteStyleEnabledChanged: { isEnabled in
                                    mapLayerViewModel.setSatelliteStyle(isEnabled: isEnabled)
                                }
                            )
                        }
                        HStack(spacing: 0) {
                            if routeNavigationViewModel.state.isNavigating {
                                MapCompass(scope: mapScope)
                                    .controlSize(.large)
                            }
                            Spacer()
                            RecenterButton(action: recenterMap)
                        }

                    }
                    .padding(.trailing, Preferences.NavigationUI.recenterButtonOuterPadding)
                    .padding(.bottom, Preferences.NavigationUI.recenterButtonOuterPadding)
                    .padding(.leading,
                        Preferences.NavigationUI.recenterButtonOuterPadding)

                    if !isSearchFocused {
                        HStack {
                            Spacer()
                            ControlView(
                                onDestinationDismissed: dismissDestination,
                                onNavigationStarted: beginNavigationMapFollowing
                            )
                        }
                        
//                        .frame(maxWidth: layout.routePanelMaximumWidth, alignment: .trailing)
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

                        if userLocationViewModel.currentLocation != nil,
                           routePlanningViewModel.destination != nil,
                           !routeNavigationViewModel.state.isNavigating {
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
        }
        .mapScope(mapScope)
        .onAppear {
            userLocationViewModel.startObserving(using: locationManager)
        }
        .task {
            try? await cyclingPathRepository.prepareForUse()
            if let area = mapViewModel.visibleSearchArea {
                mapLayerViewModel.updateVisibleArea(area)
            }
        }
        .onDisappear {
            userLocationViewModel.stopObserving()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            userLocationViewModel.startObserving(using: locationManager)
        }
        .onChange(of: cyclingPathRepository.isPrepared) { _, isPrepared in
            guard isPrepared, let area = mapViewModel.visibleSearchArea else { return }
            mapLayerViewModel.updateVisibleArea(area)
        }
        .onChange(of: cyclingPathRepository.contentRevision) { _, _ in
            guard let area = mapViewModel.visibleSearchArea else { return }
            mapLayerViewModel.updateVisibleArea(area)
        }
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: routeNavigationViewModel.state.isNavigating
        )
        .animation(
            reduceMotion ? nil : Preferences.Motion.overlayTransitionAnimation,
            value: isSearchFocused
        )
        .alert(Preferences.LocationService.locationUnavailableTitle, isPresented: $isShowingLocationError) {
            Button(Preferences.LocationService.dismissButtonTitle, role: .cancel) {}
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
        #endif
    }

    private func selectDestination(_ destination: Location) {
        routeNavigationViewModel.clearNavigation()
        routePlanningViewModel.selectDestination(destination)
    }

    private func dismissDestination() {
        withAnimation(Preferences.Motion.overlayTransitionAnimation) {
            routeNavigationViewModel.clearNavigation()
            routePlanningViewModel.clearDestination()
        }
    }

    private func recenterMap() {
        guard let coordinate = userLocationViewModel.currentLocation?.coordinate else {
            userLocationViewModel.reportLocationUnavailable(using: locationManager)
            isShowingLocationError = true
            return
        }

        if routeNavigationViewModel.state.isNavigating {
            mapViewModel.followUserHeading(from: coordinate)
        } else {
            mapViewModel.recenter(on: coordinate)
        }
    }

    private func beginNavigationMapFollowing() {
        guard let coordinate = userLocationViewModel.currentLocation?.coordinate else { return }
        mapViewModel.followUserHeading(from: coordinate)
    }
}

/// Calculates local layout constraints from the window currently available to the map experience.
private struct MainViewLayout {
    let size: CGSize
    let horizontalSizeClass: UserInterfaceSizeClass?

    var isCompactHeight: Bool {
        size.height < Preferences.MainLayout.compactHeightThreshold
    }

    var maximumSearchResultsHeight: CGFloat {
        isCompactHeight
            ? Preferences.MainLayout.compactSearchResultsMaximumHeight
            : Preferences.MainLayout.regularSearchResultsMaximumHeight
    }

    var showsLayerPicker: Bool {
        !isCompactHeight
    }

    var routePanelMaximumWidth: CGFloat {
        guard horizontalSizeClass == .regular else { return .infinity }
        return min(
            Preferences.MainLayout.regularWidthRoutePanelMaximumWidth,
            max(0, size.width - Preferences.MainLayout.routePanelHorizontalMargin)
        )
    }
}

private struct PreviewCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    func downloadSegments(
        using policy: CyclingPathSegmentDownloadPolicy
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
    
    MainView()
        .environment(locationManager)
        .environment(userLocationViewModel)
        .environment(destinationSearchViewModel)
        .environment(cyclingPathRepository)
        .environment(mapLayerViewModel)
        .environment(navigationRouteViewModel)
        .environment(navigationSessionViewModel)
}
