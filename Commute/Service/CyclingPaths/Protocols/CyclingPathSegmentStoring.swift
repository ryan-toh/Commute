import Foundation

@MainActor
protocol CyclingPathSegmentStoring {
    func loadAll() throws -> [CyclingPathSegment]
    func replaceAll(with segments: [CyclingPathSegment]) throws
    func loadSyncMetadata(for sourceID: String) throws -> CyclingPathSyncMetadata?
    func saveSyncMetadata(_ metadata: CyclingPathSyncMetadata) throws
}
