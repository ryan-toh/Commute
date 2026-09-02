//
//  CyclingPathSegmentDownloaderFactory.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

enum CyclingPathSegmentDownloaderFactory {
    static func make() -> (sourceID: String, downloader: any CyclingPathSegmentDownloading) {
        switch Preferences.CyclingPaths.downloadBackend {
        case .dataGovSG:
            return (
                Preferences.CyclingPaths.sourceID,
                CompositeCyclingPathSegmentDownloader(
                    downloaders: dataGovSGDownloaders
                )
            )
        case let .cloudflareR2(endpoint):
            return (
                Preferences.CyclingPaths.cloudflareR2SourceID,
                CFCyclingPathSegmentDownloader(endpoint: endpoint)
            )
        case .allSources:
            return (
                Preferences.CyclingPaths.allSourcesSourceID,
                CompositeCyclingPathSegmentDownloader(
                    downloaders: dataGovSGDownloaders + [
                        CFCyclingPathSegmentDownloader(
                            endpoint: Preferences.CyclingPaths.cloudflareR2Endpoint
                        )
                    ]
                )
            )
        }
    }

    private static var dataGovSGDownloaders: [any CyclingPathSegmentDownloading] {
        Preferences.CyclingPaths.dataGovSGSources.map { source in
            DataGovSGCyclingPathSegmentDownloader(
                sourceID: source.id,
                pollDownloadEndpoint: source.pollDownloadEndpoint
            )
        }
    }
}
