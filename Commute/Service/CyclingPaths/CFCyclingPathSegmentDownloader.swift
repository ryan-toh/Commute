//
//  CFCyclingPathSegmentDownloader.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

/// Downloads a full cycling-path snapshot served by a Cloudflare Worker.
struct CFCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    let endpoint: URL

    /**
        Download a full cycling-path snapshot from Cloudflare Worker backed by R2.
        - parameter policy: a CyclingPathSegmentFetchPolicy, includes options to use cache or force a refresh.
     */
    func downloadSegments(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> [CyclingPathSegment] {
        
        var request = URLRequest(url: requestURL(for: policy))
        
        // request headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = requestCachePolicy(for: policy)
        if policy == .refresh {
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }

        // fetch async
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // exception handling
        guard let response = response as? HTTPURLResponse else {
            throw CloudflareCyclingPathDownloadError.invalidResponse
        }
        
        if response.statusCode == 404 {
            throw CloudflareCyclingPathDownloadError.snapshotNotFound
        }
        
        guard (200...299).contains(response.statusCode) else {
            throw CloudflareCyclingPathDownloadError.invalidResponse
        }

        // parse payload
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode([CyclingPathSegment].self, from: data)
        } catch {
            throw CloudflareCyclingPathDownloadError.invalidPayload
        }
    }
    
    /**
        Creates a URL object representing the request with a given fetch policy.
        - parameter for: a fetch policy, includes options to use cache or force a refresh.
     */
    private func requestURL(for policy: CyclingPathSegmentFetchPolicy) -> URL {
        if policy != .refresh {
            return endpoint
        }
        
        // create URLComponents from endpoint
        guard var components = URLComponents(
            url: endpoint,
            resolvingAgainstBaseURL: false
        ) else {
            return endpoint
        }

        // ensures that the request is not served from a URL cache
        var queryItems = components.queryItems ?? []
        let cacheBuster = URLQueryItem(
            name: "check",
            value: UUID().uuidString
        )
        queryItems.append(cacheBuster)
        components.queryItems = queryItems

        // make sure we didnt make an invalid url somehow
        guard let refreshURL = components.url else {
            return endpoint
        }

        return refreshURL
    }

    private func requestCachePolicy(
        for policy: CyclingPathSegmentFetchPolicy
    ) -> URLRequest.CachePolicy {
        switch policy {
        case .useCachedData:
            .useProtocolCachePolicy
        case .refresh:
            .reloadIgnoringLocalCacheData
        }
    }
}

private enum CloudflareCyclingPathDownloadError: LocalizedError {
    case invalidResponse
    case snapshotNotFound
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            Preferences.CyclingPaths.CloudflareDownloadError.invalidResponseMessage
        case .snapshotNotFound:
            Preferences.CyclingPaths.CloudflareDownloadError.snapshotNotFoundMessage
        case .invalidPayload:
            Preferences.CyclingPaths.CloudflareDownloadError.invalidPayloadMessage
        }
    }
}
