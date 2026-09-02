//
//  CyclingPathSyncMetadata.swift
//  Commute
//
//  Created by Ryan on 2/9/26.
//

import Foundation

struct CyclingPathSyncMetadata: Codable, Hashable {
    let sourceID: String
    let lastSuccessfulSyncAt: Date?
    let lastUpdateCheckAt: Date?
}
