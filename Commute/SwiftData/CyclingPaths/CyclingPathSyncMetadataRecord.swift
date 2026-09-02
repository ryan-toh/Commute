//
//  CyclingPathSyncMetadataRecord.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation
import SwiftData

@Model
final class CyclingPathSyncMetadataRecord {
    @Attribute(.unique) var sourceID: String
    var lastSuccessfulSyncAt: Date?
    var lastUpdateCheckAt: Date?

    init(metadata: CyclingPathSyncMetadata) {
        sourceID = metadata.sourceID
        lastSuccessfulSyncAt = metadata.lastSuccessfulSyncAt
        lastUpdateCheckAt = metadata.lastUpdateCheckAt
    }

    func update(with metadata: CyclingPathSyncMetadata) {
        lastSuccessfulSyncAt = metadata.lastSuccessfulSyncAt
        lastUpdateCheckAt = metadata.lastUpdateCheckAt
    }

    func makeMetadata() -> CyclingPathSyncMetadata {
        CyclingPathSyncMetadata(
            sourceID: sourceID,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
            lastUpdateCheckAt: lastUpdateCheckAt
        )
    }
}
