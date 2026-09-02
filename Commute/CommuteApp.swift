//
//  CommuteApp.swift
//  Commute
//
//  Created by Ryan on 26/6/26.
//

import SwiftUI
import Observation
import SwiftData

@main
struct CommuteApp: App {
    @State private var locationManager: UserLocationManager
    @State private var userLocationViewModel: UserLocationViewModel
    @State private var destinationSearchViewModel: DestinationSearchViewModel
    @State private var cyclingPathRepository: CyclingPathRepository
    @State private var mapLayerViewModel: MapLayerViewModel
    @State private var navigationViewModel: RoutePlanningViewModel
    @State private var navigationSessionViewModel: RouteNavigationViewModel
    private let cyclingPathModelContainer: ModelContainer

    init() {
        let locationManager = UserLocationManager()
        let userLocationViewModel = UserLocationViewModel()
        let destinationSearchViewModel = DestinationSearchViewModel(
            destinationSearchService: MapKitDestinationSearchService()
        )
        let cyclingPathModelContainer = try! ModelContainer(
            for: CyclingPathSegmentRecord.self,
            CyclingPathSyncMetadataRecord.self
        )
        let cyclingPathDownload = CyclingPathSegmentDownloaderFactory.make()
        let cyclingPathRepository = CyclingPathRepository(
            downloader: cyclingPathDownload.downloader,
            store: SwiftDataCyclingPathSegmentStore(
                modelContext: ModelContext(cyclingPathModelContainer)
            ),
            sourceID: cyclingPathDownload.sourceID
        )
        let routePlanningService = RoutePlanningServiceFactory.make(
            using: cyclingPathRepository
        )
        let mapLayerViewModel = MapLayerViewModel(
            cyclingPathRepository: cyclingPathRepository
        )
        let navigationViewModel = RoutePlanningViewModel(
            routePlanningService: routePlanningService,
            placeDetailsService: MapKitPlaceDetailsService()
        )
        let navigationSessionViewModel = RouteNavigationViewModel(
            routePlanningService: routePlanningService,
            routeProgressCalculator: RouteProgressCalculator()
        )

        _locationManager = State(initialValue: locationManager)
        _userLocationViewModel = State(initialValue: userLocationViewModel)
        _destinationSearchViewModel = State(initialValue: destinationSearchViewModel)
        _cyclingPathRepository = State(initialValue: cyclingPathRepository)
        _mapLayerViewModel = State(initialValue: mapLayerViewModel)
        _navigationViewModel = State(initialValue: navigationViewModel)
        _navigationSessionViewModel = State(initialValue: navigationSessionViewModel)
        self.cyclingPathModelContainer = cyclingPathModelContainer
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(locationManager)
                .environment(userLocationViewModel)
                .environment(destinationSearchViewModel)
                .environment(cyclingPathRepository)
                .environment(mapLayerViewModel)
                .environment(navigationViewModel)
                .environment(navigationSessionViewModel)
                .modelContainer(cyclingPathModelContainer)
        }
    }
}
