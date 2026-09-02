//
//  CyclingPathSegmentDownloading.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

/// Requires returning CyclingPathSegments asynchronously
protocol CyclingPathSegmentDownloading {
    func downloadSegments(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> [CyclingPathSegment]
}

enum CyclingPathSegmentFetchPolicy: Sendable {
    case useCachedData
    case refresh
}

extension CyclingPathSegmentDownloading {
    func downloadSegments() async throws -> [CyclingPathSegment] {
        try await downloadSegments(using: .useCachedData)
    }
}
