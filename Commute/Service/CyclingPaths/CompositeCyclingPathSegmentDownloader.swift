struct CompositeCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    let downloaders: [any CyclingPathSegmentDownloading]

    func downloadSegments(
        using policy: CyclingPathSegmentDownloadPolicy
    ) async throws -> [CyclingPathSegment] {
        var segments: [CyclingPathSegment] = []

        for downloader in downloaders {
            segments += try await downloader.downloadSegments(using: policy)
        }

        return Dictionary(
            segments.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        .values
        .sorted { $0.id < $1.id }
    }
}
