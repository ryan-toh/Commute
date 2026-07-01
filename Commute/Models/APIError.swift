//
//  APIError.swift
//  Commute
//
//  Created by Ryan on 30/6/26.
//

enum APIError: Error {
    case invalidURL(String)
    case requestFailed(Error)
    case invalidResponse
    case apiError(String)
    case missingDownloadURL
}
