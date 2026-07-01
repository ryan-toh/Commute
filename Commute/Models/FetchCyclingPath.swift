//
//  FetchCyclingPath.swift
//  Commute
//
//  Created by Ryan on 27/6/26.
//

import Foundation

let baseURLString = "https://api-open.data.gov.sg/v1/public/api/datasets"
let datasetID = "d_8f468b25193f64be8a16fa7d8f60f553"

struct PollDownloadResponse: Decodable {
    let code: Int
    let errMsg: String?
    let data: PollDownloadData?
}

struct PollDownloadData: Decodable {
    let url: String
}

final class DataGovSGClient {
    private let baseURLString: String
    private let urlSession: URLSession

    init(
        baseURLString: String,
        urlSession: URLSession = .shared
    ) {
        self.baseURLString = baseURLString
        self.urlSession = urlSession
    }

    func fetchDatasetText(datasetID: String) async throws -> String {
        let downloadURL = try await fetchDownloadURL(datasetID: datasetID)
        return try await fetchText(from: downloadURL)
    }

    private func fetchDownloadURL(datasetID: String) async throws -> URL {
        let urlString = "\(baseURLString)/\(datasetID)/poll-download"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL(urlString)
        }

        let data = try await fetchData(from: url)
        let decodedResponse = try JSONDecoder().decode(PollDownloadResponse.self, from: data)

        guard decodedResponse.code == 0 else {
            throw APIError.apiError(decodedResponse.errMsg ?? "Unknown API error")
        }

        guard let downloadURLString = decodedResponse.data?.url,
              let downloadURL = URL(string: downloadURLString) else {
            throw APIError.missingDownloadURL
        }

        return downloadURL
    }

    private func fetchText(from url: URL) async throws -> String {
        let data = try await fetchData(from: url)

        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.invalidResponse
        }

        return text
    }

    private func fetchData(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await urlSession.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }

            return data
        } catch {
            throw APIError.requestFailed(error)
        }
    }
}
