//
//  CyclingPathRepository.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation
import Observation

/// Maintains persisted cycling-path segments and their read-optimized indexes.
@MainActor
@Observable
final class CyclingPathRepository {
    private(set) var isPrepared = false
    private(set) var preparationError: Error?
    private(set) var contentRevision = 0

    private let downloader: any CyclingPathSegmentDownloading
    private let store: any CyclingPathSegmentStoring
    private let spatialIndex: CyclingPathSpatialIndex
    private(set) var network: CyclingPathNetwork
    private let sourceID: String
    private var isPreparing = false

    init(
        downloader: any CyclingPathSegmentDownloading,
        store: any CyclingPathSegmentStoring,
        sourceID: String = Preferences.CyclingPaths.sourceID
    ) {
        self.downloader = downloader
        self.store = store
        self.spatialIndex = CyclingPathSpatialIndex()
        self.network = CyclingPathNetworkBuilder().makeNetwork(
            from: [],
            maximumConnectionDistanceMeters: Preferences.RoutePlanning.maximumCyclingPathNetworkConnectionDistanceMeters
        )
        self.sourceID = sourceID
    }

    func prepareForUse() async throws {
        guard !isPrepared, !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        do {
            let storedSegments = try store.loadAll()
            let metadata = try store.loadSyncMetadata(for: sourceID)
            if storedSegments.isEmpty || metadata == nil {
                // A new or manually-cleared local database must not be repopulated
                // from an older URLSession cache entry.
                try await downloadStoreAndIndex(using: .refresh)
            } else {
                spatialIndex.rebuild(with: storedSegments)
                network = makeNetwork(from: storedSegments)
                contentRevision += 1
            }

            isPrepared = true
            preparationError = nil
        } catch {
            preparationError = error
            throw error
        }
    }

    @discardableResult
    func refreshIfAllowed() async throws -> Bool {
        guard !isPreparing else { return false }

        let metadata = try store.loadSyncMetadata(for: sourceID)
        if let lastUpdateCheckAt = metadata?.lastUpdateCheckAt,
           Date.now.timeIntervalSince(lastUpdateCheckAt) < Preferences.CyclingPaths.minimumRefreshInterval {
            return false
        }

        isPreparing = true
        defer { isPreparing = false }

        do {
            try store.saveSyncMetadata(
                CyclingPathSyncMetadata(
                    sourceID: sourceID,
                    lastSuccessfulSyncAt: metadata?.lastSuccessfulSyncAt,
                    lastUpdateCheckAt: .now
                )
            )
            try await downloadStoreAndIndex(using: .refresh)
            isPrepared = true
            preparationError = nil
            return true
        } catch {
            preparationError = error
            throw error
        }
    }

    /// Downloads and replaces the local snapshot without applying the normal refresh interval.
    /// Intended for an explicit development or user-requested refresh.
    @discardableResult
    func refreshNow() async throws -> Bool {
        guard !isPreparing else { return false }
        isPreparing = true
        defer { isPreparing = false }

        do {
            try await downloadStoreAndIndex(using: .refresh)
            isPrepared = true
            preparationError = nil
            return true
        } catch {
            preparationError = error
            throw error
        }
    }

    /// Removes the local cycling-path snapshot while preserving the app's other data.
    @discardableResult
    func deleteLocalSegments() throws -> Bool {
        guard !isPreparing else { return false }

        try store.replaceAll(with: [])
        spatialIndex.rebuild(with: [])
        network = makeNetwork(from: [])
        isPrepared = false
        preparationError = nil
        contentRevision += 1
        return true
    }

    func candidateSegments(near coordinate: LocationCoordinate, within radiusMeters: Double) -> [CyclingPathSegment] {
        spatialIndex.candidateSegments(near: coordinate, within: radiusMeters)
    }

    func segments(intersecting area: PlaceSearchArea) -> [CyclingPathSegment] {
        let latitudeDelta = area.latitudeDelta / 2
        let longitudeDelta = area.longitudeDelta / 2
        return spatialIndex.segments(
            intersecting: CyclingPathBounds(
                minimumLatitude: area.center.latitude - latitudeDelta,
                maximumLatitude: area.center.latitude + latitudeDelta,
                minimumLongitude: area.center.longitude - longitudeDelta,
                maximumLongitude: area.center.longitude + longitudeDelta
            )
        )
    }

    private func downloadStoreAndIndex(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws {
        let segments = try await downloader.downloadSegments(using: policy)
        guard !segments.isEmpty else { throw CyclingPathRepositoryError.emptyDataset }

        let uniqueSegments = Dictionary(
            segments.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        .values
        .sorted { $0.id < $1.id }
        try store.replaceAll(with: uniqueSegments)
        try store.saveSyncMetadata(
            CyclingPathSyncMetadata(
                sourceID: sourceID,
                lastSuccessfulSyncAt: .now,
                lastUpdateCheckAt: .now
            )
        )
        spatialIndex.rebuild(with: uniqueSegments)
        network = makeNetwork(from: uniqueSegments)
        contentRevision += 1
    }

    private func makeNetwork(from segments: [CyclingPathSegment]) -> CyclingPathNetwork {
        CyclingPathNetworkBuilder().makeNetwork(
            from: segments,
            maximumConnectionDistanceMeters: Preferences.RoutePlanning.maximumCyclingPathNetworkConnectionDistanceMeters
        )
    }
}

enum CyclingPathRepositoryError: LocalizedError {
    case emptyDataset

    var errorDescription: String? {
        switch self {
        case .emptyDataset: "The cycling path download did not contain any valid segments."
        }
    }
}
