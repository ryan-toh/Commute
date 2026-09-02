import Foundation

protocol CyclingPathSegmentDownloading {
    func downloadSegments(
        using policy: CyclingPathSegmentDownloadPolicy
    ) async throws -> [CyclingPathSegment]
}

enum CyclingPathSegmentDownloadPolicy: Sendable {
    case useProtocolCache
    case forceRefresh

    var urlRequestCachePolicy: URLRequest.CachePolicy {
        switch self {
        case .useProtocolCache: .useProtocolCachePolicy
        case .forceRefresh: .reloadIgnoringLocalCacheData
        }
    }

    var shouldRevalidate: Bool {
        self == .forceRefresh
    }
}

extension CyclingPathSegmentDownloading {
    func downloadSegments() async throws -> [CyclingPathSegment] {
        try await downloadSegments(using: .useProtocolCache)
    }
}
