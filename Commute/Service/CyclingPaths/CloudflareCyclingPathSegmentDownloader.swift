import Foundation

/// Downloads a full cycling-path snapshot served by a Cloudflare Worker backed by R2.
///
/// The endpoint may return either a JSON array of `CyclingPathSegment` values or a
/// versioned envelope containing a `segments` array. Its HTTP cache headers control
/// URLSession's normal cache and revalidation behaviour.
struct CloudflareCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    let endpoint: URL

    func downloadSegments(
        using policy: CyclingPathSegmentDownloadPolicy
    ) async throws -> [CyclingPathSegment] {
        var request = URLRequest(url: requestURL(for: policy))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = policy.urlRequestCachePolicy
        if policy.shouldRevalidate {
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw CloudflareCyclingPathDownloadError.invalidResponse
        }
        if response.statusCode == 404 {
            throw CloudflareCyclingPathDownloadError.snapshotNotFound
        }
        guard (200...299).contains(response.statusCode) else {
            throw CloudflareCyclingPathDownloadError.invalidResponse
        }

        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(CloudflareSegmentsEnvelope.self, from: data) {
            return envelope.segments
        }

        do {
            return try decoder.decode([CyclingPathSegment].self, from: data)
        } catch {
            throw CloudflareCyclingPathDownloadError.invalidPayload
        }
    }

    private func requestURL(for policy: CyclingPathSegmentDownloadPolicy) -> URL {
        guard policy.shouldRevalidate,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return endpoint
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "check", value: UUID().uuidString))
        components.queryItems = queryItems
        return components.url ?? endpoint
    }
}

private struct CloudflareSegmentsEnvelope: Decodable {
    let segments: [CyclingPathSegment]
}

private enum CloudflareCyclingPathDownloadError: LocalizedError {
    case invalidResponse
    case snapshotNotFound
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The cycling path service returned an invalid response."
        case .snapshotNotFound:
            "The cycling path service does not have a published snapshot."
        case .invalidPayload:
            "The cycling path service returned an invalid segment payload."
        }
    }
}
