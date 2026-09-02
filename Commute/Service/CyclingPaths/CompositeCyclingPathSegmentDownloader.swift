//
//  CompositeCyclingPathSegmentDownloader.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

/// Downloads all cycling-path snapshots from chosen CyclingPathSegmentDownloading implementations
struct CompositeCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    let downloaders: [any CyclingPathSegmentDownloading]

    func downloadSegments(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> [CyclingPathSegment] {
        var segmentsByID: [String: CyclingPathSegment] = [:]

        for downloader in downloaders {
            let downloadedSegments = try await downloader.downloadSegments(
                using: policy
            )

            for segment in downloadedSegments {
                if segmentsByID[segment.id] == nil {
                    segmentsByID[segment.id] = segment
                }
            }
        }

        return segmentsByID.values.sorted { first, second in
            first.id < second.id
        }
    }
}
