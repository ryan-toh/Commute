//
//  DataGovSGCyclingPathSegmentDownloader.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

struct DataGovSGSource: Sendable {
    let id: String
    let pollDownloadEndpoint: URL
}

struct DataGovSGCyclingPathSegmentDownloader: CyclingPathSegmentDownloading {
    let sourceID: String
    let pollDownloadEndpoint: URL

    func downloadSegments(
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> [CyclingPathSegment] {
        let pollResponse: PollDownloadResponse = try await fetch(
            PollDownloadResponse.self,
            from: pollDownloadEndpoint,
            using: policy
        )
        guard pollResponse.code == 0, let downloadURL = pollResponse.data?.url else {
            throw DataGovSGDownloadError.requestFailed(pollResponse.errorMessage)
        }

        let featureCollection: GeoJSONFeatureCollection = try await fetch(
            GeoJSONFeatureCollection.self,
            from: downloadURL,
            using: policy
        )
        return featureCollection.features.compactMap(makeSegment(from:))
    }

    private func fetch<Response: Decodable>(
        _ type: Response.Type,
        from url: URL,
        using policy: CyclingPathSegmentFetchPolicy
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.cachePolicy = requestCachePolicy(for: policy)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw DataGovSGDownloadError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
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

    private func makeSegment(from feature: GeoJSONFeature) -> CyclingPathSegment? {
        guard feature.geometry.type == "LineString",
              let identifier = feature.properties.objectID,
              feature.geometry.coordinates.count >= 2 else {
            return nil
        }

        let coordinates = feature.geometry.coordinates.compactMap(makeCoordinate(from:))
        guard coordinates.count >= 2 else { return nil }

        return CyclingPathSegment(
            id: "\(sourceID).\(identifier)",
            name: feature.properties.pathName,
            lengthMeters: feature.properties.lengthMeters,
            coordinates: coordinates
        )
    }

    private func makeCoordinate(from coordinate: [Double]) -> LocationCoordinate? {
        guard coordinate.count >= 2 else { return nil }

        let longitude = coordinate[0]
        let latitude = coordinate[1]
        guard latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return nil
        }

        return LocationCoordinate(latitude: latitude, longitude: longitude)
    }
}

private enum DataGovSGDownloadError: LocalizedError {
    case requestFailed(String?)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case let .requestFailed(message): message ?? "Unable to prepare the cycling path download."
        case .invalidResponse: "The cycling path service returned an invalid response."
        }
    }
}

private struct PollDownloadResponse: Decodable {
    let code: Int
    let errorMessage: String?
    let data: DownloadData?

    enum CodingKeys: String, CodingKey {
        case code
        case errorMessage = "errMsg"
        case data
    }
}

private struct DownloadData: Decodable {
    let url: URL
}

private struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONLineString
    let properties: GeoJSONCyclingPathProperties
}

private struct GeoJSONLineString: Decodable {
    let type: String
    let coordinates: [[Double]]

    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        if type == "LineString" {
            coordinates = try container.decode([[Double]].self, forKey: .coordinates)
        } else {
            coordinates = []
        }
    }
}

private struct GeoJSONCyclingPathProperties: Decodable {
    let objectID: Int?
    let pathName: String?
    let lengthMeters: Double?

    enum CodingKeys: String, CodingKey {
        case cyclingPathObjectID = "OBJECTID_1"
        case parkConnectorObjectID = "OBJECTID"
        case cyclingPathName = "CYL_PATH"
        case parkName = "PARK"
        case parkConnectorLoopName = "PCN_LOOP"
        case cyclingPathLength = "SHAPE_1.LEN"
        case parkConnectorLength = "SHAPE.LEN"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let cyclingPathObjectID = try container.decodeIfPresent(
            Int.self,
            forKey: .cyclingPathObjectID
        )
        let parkConnectorObjectID = try container.decodeIfPresent(
            Int.self,
            forKey: .parkConnectorObjectID
        )
        let cyclingPathName = try container.decodeIfPresent(
            String.self,
            forKey: .cyclingPathName
        )
        let parkName = try container.decodeIfPresent(String.self, forKey: .parkName)
        let parkConnectorLoopName = try container.decodeIfPresent(
            String.self,
            forKey: .parkConnectorLoopName
        )
        let cyclingPathLength = try container.decodeIfPresent(
            Double.self,
            forKey: .cyclingPathLength
        )
        let parkConnectorLength = try container.decodeIfPresent(
            Double.self,
            forKey: .parkConnectorLength
        )

        objectID = cyclingPathObjectID ?? parkConnectorObjectID
        pathName = cyclingPathName ?? parkName ?? parkConnectorLoopName
        lengthMeters = cyclingPathLength ?? parkConnectorLength
    }
}
