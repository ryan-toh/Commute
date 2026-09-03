//
//  RouteComparisonView.swift
//  Commute
//
//  Created by Ryan on 1/9/26.
//


import MapKit
import SwiftUI
import SwiftData
// EXTREMELY UGLY FOR DEV PURPOSES

/// A debug-only visual comparison between the baseline and cycling-path-aware planners.
struct RouteComparisonView: View {
    let origin: Location
    let destination: Location
    let cyclingPathRepository: CyclingPathRepository

    @Query(sort: \CyclingPathSegmentRecord.id) private var cyclingPathRecords: [CyclingPathSegmentRecord]

    @State private var mapKitRoute: Route?
    @State private var cyclingPathRoute: Route?
    @State private var cyclingPathDecisionTrace: CyclingPathRouteDecisionTrace?
    @State private var mapKitError: Error?
    @State private var cyclingPathError: Error?
    @State private var isComparing = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition) {
                    if let mapKitRoute {
                        MapPolyline(coordinates: mapCoordinates(for: mapKitRoute))
                            .stroke(
                                Preferences.DevTools.mapKitRouteColor,
                                lineWidth: Preferences.DevTools.routeLineWidth
                            )
                    }

                    if let cyclingPathRoute {
                        MapPolyline(coordinates: mapCoordinates(for: cyclingPathRoute))
                            .stroke(
                                Preferences.DevTools.cyclingPathRouteColor,
                                lineWidth: Preferences.DevTools.routeLineWidth
                            )
                    }

                    Marker(Preferences.DevTools.originLabel, coordinate: mapCoordinate(from: origin.coordinate))
                        .tint(.green)
                    Marker(Preferences.DevTools.destinationLabel, coordinate: mapCoordinate(from: destination.coordinate))
                        .tint(.red)
                }

                List {
                    Section(Preferences.DevTools.routesSectionTitle) {
                        routeSummary(
                            Preferences.DevTools.mapKitRouteLabel,
                            route: mapKitRoute,
                            error: mapKitError,
                            color: Preferences.DevTools.mapKitRouteColor
                        )
                        routeSummary(
                            Preferences.DevTools.cyclingPathRouteLabel,
                            route: cyclingPathRoute,
                            error: cyclingPathError,
                            color: Preferences.DevTools.cyclingPathRouteColor
                        )
                    }

                    Section(Preferences.DevTools.cyclingPathDatabaseSectionTitle) {
                        LabeledContent(Preferences.DevTools.repositoryPreparedLabel) {
                            Text(
                                cyclingPathRepository.isPrepared
                                    ? Preferences.DevTools.yesLabel
                                    : Preferences.DevTools.noLabel
                            )
                        }
                        LabeledContent(Preferences.DevTools.storedSegmentCountLabel) {
                            Text(cyclingPathRecords.count.formatted())
                        }
                        LabeledContent(Preferences.DevTools.indexedCandidateCountLabel) {
                            Text(indexedCandidateCount.formatted())
                        }
                        if let error = cyclingPathRepository.preparationError {
                            LabeledContent(Preferences.DevTools.preparationErrorLabel) {
                                Text(error.localizedDescription)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    if let cyclingPathDecisionTrace {
                        Section(Preferences.DevTools.routeDecisionSectionTitle) {
                            LabeledContent(Preferences.DevTools.excursionAnchorCountLabel) {
                                Text(cyclingPathDecisionTrace.excursionAnchorCount.formatted())
                            }
                            LabeledContent(Preferences.DevTools.compatibleAnchorPairCountLabel) {
                                Text(cyclingPathDecisionTrace.compatibleAnchorPairCount.formatted())
                            }
                            LabeledContent(Preferences.DevTools.candidateExcursionCountLabel) {
                                Text(cyclingPathDecisionTrace.candidateExcursionCount.formatted())
                            }
                            LabeledContent(Preferences.DevTools.viableCandidateCountLabel) {
                                Text(cyclingPathDecisionTrace.viableCandidateCount.formatted())
                            }
                            LabeledContent(Preferences.DevTools.selectedCandidateLabel) {
                                Text(selectedCandidateTitle(in: cyclingPathDecisionTrace))
                            }
                        }

                        Section(Preferences.DevTools.candidateDecisionsSectionTitle) {
                            if cyclingPathDecisionTrace.candidateDecisions.isEmpty {
                                Text(Preferences.DevTools.noCandidateDecisionsLabel)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(cyclingPathDecisionTrace.candidateDecisions) { decision in
                                    candidateDecisionRow(
                                        decision,
                                        isSelected: decision.id == cyclingPathDecisionTrace.selectedCandidateID
                                    )
                                }
                            }
                        }
                    }

                    Section(Preferences.DevTools.sampleSegmentsSectionTitle) {
                        ForEach(cyclingPathRecords.prefix(Preferences.DevTools.sampleSegmentLimit)) { record in
                            VStack(alignment: .leading) {
                                Text(record.name ?? Preferences.DevTools.unnamedSegmentLabel)
                                Text(record.id)
                                Text(String(format: Preferences.DevTools.coordinateCountFormat, coordinateCount(for: record)))
                            }
                            .font(.caption)
                        }
                    }
                }
                .frame(height: Preferences.DevTools.inspectorHeight)
            }
            .navigationTitle(Preferences.DevTools.routeComparisonTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Preferences.DevTools.compareRoutesTitle) {
                        Task { await compareRoutes() }
                    }
                    .disabled(isComparing)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(Preferences.DevTools.retrySyncTitle) {
                        Task {
                            try? await cyclingPathRepository.prepareForUse()
                            await compareRoutes()
                        }
                    }
                    .disabled(isComparing || cyclingPathRepository.isPrepared)
                }
            }
            .overlay {
                if isComparing {
                    ProgressView()
                }
            }
            .task {
                await compareRoutes()
            }
        }
    }

    @ViewBuilder
    private func routeSummary(
        _ title: String,
        route: Route?,
        error: Error?,
        color: Color
    ) -> some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(title)
                if let route {
                    Text("\(String(format: Preferences.DevTools.routeDistanceFormat, Int(route.distanceMeters))) • \(String(format: Preferences.DevTools.routeDurationFormat, Int(route.expectedTravelTime / 60)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(Preferences.DevTools.routeNotPlannedLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func compareRoutes() async {
        isComparing = true
        defer { isComparing = false }
        mapKitRoute = nil
        cyclingPathRoute = nil
        cyclingPathDecisionTrace = nil
        mapKitError = nil
        cyclingPathError = nil

        let mapKitService = MapKitRoutePlanningService()
        let cyclingPathService = CyclingPathRoutePlanningService(
            mapKitService: mapKitService,
            cyclingPathRepository: cyclingPathRepository
        )

        do {
            mapKitRoute = try await mapKitService.planCyclingRoute(from: origin, to: destination)
        } catch {
            mapKitError = error
        }

        do {
            let result = try await cyclingPathService.planCyclingRouteWithDecisionTrace(
                from: origin,
                to: destination
            )
            cyclingPathRoute = result.route
            cyclingPathDecisionTrace = result.trace
        } catch {
            cyclingPathError = error
        }

        updateCameraPosition()
    }

    private func updateCameraPosition() {
        let coordinates = (mapKitRoute?.coordinates ?? []) + (cyclingPathRoute?.coordinates ?? [])
        guard let first = coordinates.first else { return }

        let latitudeRange = coordinates.map(\.latitude)
        let longitudeRange = coordinates.map(\.longitude)
        let latitudeDelta = max((latitudeRange.max() ?? first.latitude) - (latitudeRange.min() ?? first.latitude), 0.002)
        let longitudeDelta = max((longitudeRange.max() ?? first.longitude) - (longitudeRange.min() ?? first.longitude), 0.002)
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: ((latitudeRange.max() ?? first.latitude) + (latitudeRange.min() ?? first.latitude)) / 2,
                    longitude: ((longitudeRange.max() ?? first.longitude) + (longitudeRange.min() ?? first.longitude)) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta * Preferences.DevTools.routeCameraPaddingFactor,
                    longitudeDelta: longitudeDelta * Preferences.DevTools.routeCameraPaddingFactor
                )
            )
        )
    }

    private var indexedCandidateCount: Int {
        guard let mapKitRoute else { return 0 }

        let candidates = mapKitRoute.coordinates.reduce(into: Set<String>()) { result, coordinate in
            cyclingPathRepository.candidateSegments(
                near: coordinate,
                within: Preferences.RoutePlanning.cyclingPathSearchRadiusMeters
            )
            .forEach { result.insert($0.id) }
        }
        return candidates.count
    }

    private func coordinateCount(for record: CyclingPathSegmentRecord) -> Int {
        (try? record.makeSegment().coordinates.count) ?? 0
    }

    @ViewBuilder
    private func candidateDecisionRow(
        _ decision: CyclingPathRouteCandidateDecision,
        isSelected: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Preferences.DevTools.candidateExcursionLabel)
            Text(
                String(
                    format: Preferences.DevTools.cyclingPathDistanceFormat,
                    Int(decision.cyclingPathDistanceMeters)
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(candidateOutcomeTitle(for: decision.outcome, isSelected: isSelected))
                .font(.caption)
                .foregroundStyle(candidateOutcomeColor(for: decision.outcome, isSelected: isSelected))
        }
    }

    private func selectedCandidateTitle(in trace: CyclingPathRouteDecisionTrace) -> String {
        guard trace.selectedCandidateID != nil else {
            return Preferences.DevTools.directRouteSelectionLabel
        }
        return Preferences.DevTools.candidateExcursionLabel
    }

    private func candidateOutcomeTitle(
        for outcome: CyclingPathRouteCandidateOutcome,
        isSelected: Bool
    ) -> String {
        switch outcome {
        case .connectorRouteUnavailable:
            Preferences.DevTools.connectorRouteUnavailableLabel
        case .invalidConfiguration:
            Preferences.DevTools.invalidCandidateConfigurationLabel
        case let .exceededTimePenalty(addedTime):
            String(
                format: Preferences.DevTools.exceededTimePenaltyFormat,
                Int(addedTime / 60)
            )
        case .viable:
            isSelected
                ? Preferences.DevTools.selectedCandidateOutcomeLabel
                : Preferences.DevTools.viableCandidateLabel
        }
    }

    private func candidateOutcomeColor(
        for outcome: CyclingPathRouteCandidateOutcome,
        isSelected: Bool
    ) -> Color {
        switch outcome {
        case .connectorRouteUnavailable, .invalidConfiguration, .exceededTimePenalty:
            .red
        case .viable:
            isSelected ? .green : .secondary
        }
    }

    private func mapCoordinates(for route: Route) -> [CLLocationCoordinate2D] {
        route.coordinates.map(mapCoordinate(from:))
    }

    private func mapCoordinate(from coordinate: LocationCoordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
