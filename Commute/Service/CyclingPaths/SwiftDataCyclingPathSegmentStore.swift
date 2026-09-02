import Foundation
import SwiftData

@MainActor
final class SwiftDataCyclingPathSegmentStore: CyclingPathSegmentStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadAll() throws -> [CyclingPathSegment] {
        try modelContext.fetch(FetchDescriptor<CyclingPathSegmentRecord>()).map { try $0.makeSegment() }
    }

    func replaceAll(with segments: [CyclingPathSegment]) throws {
        let records = try segments.map { segment in
            try CyclingPathSegmentRecord(segment: segment)
        }
        try modelContext.delete(model: CyclingPathSegmentRecord.self)
        records.forEach { record in
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    func loadSyncMetadata(for sourceID: String) throws -> CyclingPathSyncMetadata? {
        let descriptor = FetchDescriptor<CyclingPathSyncMetadataRecord>(
            predicate: #Predicate { $0.sourceID == sourceID }
        )
        return try modelContext.fetch(descriptor).first?.makeMetadata()
    }

    func saveSyncMetadata(_ metadata: CyclingPathSyncMetadata) throws {
        let descriptor = FetchDescriptor<CyclingPathSyncMetadataRecord>(
            predicate: #Predicate { $0.sourceID == metadata.sourceID }
        )

        if let record = try modelContext.fetch(descriptor).first {
            record.update(with: metadata)
        } else {
            modelContext.insert(CyclingPathSyncMetadataRecord(metadata: metadata))
        }

        try modelContext.save()
    }
}
