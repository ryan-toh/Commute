import CoreLocation
import Foundation
import MapKit
import Observation

/// Owns the optional map-layer selection and the cycling paths currently needed on screen.
@MainActor
@Observable
final class MapLayerViewModel {
    private(set) var enabledLayers = Set(MapLayer.allCases)
    private(set) var isSatelliteStyleEnabled = false
    private(set) var loadedCyclingPathPolylines: [CyclingPathMapPolyline] = []

    private let cyclingPathRepository: CyclingPathRepository
    private let polylineCache = NSCache<NSString, MKPolyline>()
    private var cachedRepositoryContentRevision: Int?
    private var retainedArea: PlaceSearchArea?

    init(cyclingPathRepository: CyclingPathRepository) {
        self.cyclingPathRepository = cyclingPathRepository
        polylineCache.countLimit = Preferences.MapLayers.cyclingPathPolylineCacheLimit
    }

    func setLayer(_ layer: MapLayer, isEnabled: Bool) {
        if isEnabled {
            enabledLayers.insert(layer)
        } else if enabledLayers.count > 1 {
            enabledLayers.remove(layer)
        }
    }

    func setSatelliteStyle(isEnabled: Bool) {
        isSatelliteStyleEnabled = isEnabled
    }

    func updateVisibleArea(_ area: PlaceSearchArea) {
        guard enabledLayers.contains(.cyclingPaths), cyclingPathRepository.isPrepared else {
            clearLoadedPolylines()
            return
        }

        guard area.latitudeDelta <= Preferences.MapLayers.maximumCyclingPathLayerLatitudeDelta,
              area.longitudeDelta <= Preferences.MapLayers.maximumCyclingPathLayerLongitudeDelta else {
            clearLoadedPolylines()
            return
        }

        let didInvalidateCache = invalidatePolylineCacheIfNeeded()
        if !didInvalidateCache, retainedArea?.contains(area) == true {
            return
        }

        let expandedArea = area.expanded(
            by: Preferences.MapLayers.cyclingPathLayerRetainedAreaPaddingFactor
        )
        loadedCyclingPathPolylines = cyclingPathRepository
            .segments(intersecting: expandedArea)
            .sorted { distanceToVisibleAreaCenter(for: $0, area: expandedArea) < distanceToVisibleAreaCenter(for: $1, area: expandedArea) }
            .prefix(Preferences.MapLayers.maximumRenderedCyclingPathSegments)
            .map { CyclingPathMapPolyline(id: $0.id, polyline: cachedPolyline(for: $0)) }
        retainedArea = expandedArea
    }

    private func clearLoadedPolylines() {
        loadedCyclingPathPolylines = []
        retainedArea = nil
    }

    private func invalidatePolylineCacheIfNeeded() -> Bool {
        guard cachedRepositoryContentRevision != cyclingPathRepository.contentRevision else {
            return false
        }
        polylineCache.removeAllObjects()
        cachedRepositoryContentRevision = cyclingPathRepository.contentRevision
        retainedArea = nil
        return true
    }

    private func cachedPolyline(for segment: CyclingPathSegment) -> MKPolyline {
        let cacheKey = segment.id as NSString
        if let cachedPolyline = polylineCache.object(forKey: cacheKey) {
            return cachedPolyline
        }

        let coordinates = simplifiedCoordinates(for: segment).map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        polylineCache.setObject(polyline, forKey: cacheKey)
        return polyline
    }

    private func simplifiedCoordinates(for segment: CyclingPathSegment) -> [LocationCoordinate] {
        let coordinates = segment.coordinates
        let maximumPointCount = Preferences.MapLayers.maximumRenderedPointsPerCyclingPath
        guard coordinates.count > maximumPointCount,
              let lastCoordinate = coordinates.last else {
            return coordinates
        }

        let pointStride = Int(ceil(Double(coordinates.count - 1) / Double(maximumPointCount - 1)))
        var simplified = Swift.stride(from: 0, to: coordinates.count, by: pointStride)
            .map { coordinates[$0] }
        if simplified.last != lastCoordinate {
            simplified.append(lastCoordinate)
        }
        return simplified
    }

    private func distanceToVisibleAreaCenter(
        for segment: CyclingPathSegment,
        area: PlaceSearchArea
    ) -> Double {
        guard let bounds = segment.bounds else { return .infinity }

        let segmentLatitude = (bounds.minimumLatitude + bounds.maximumLatitude) / 2
        let segmentLongitude = (bounds.minimumLongitude + bounds.maximumLongitude) / 2
        let latitudeDelta = segmentLatitude - area.center.latitude
        let longitudeDelta = segmentLongitude - area.center.longitude
        return latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta
    }
}

private extension PlaceSearchArea {
    func expanded(by factor: Double) -> Self {
        Self(
            center: center,
            latitudeDelta: latitudeDelta * factor,
            longitudeDelta: longitudeDelta * factor
        )
    }

    func contains(_ other: Self) -> Bool {
        let minimumLatitude = center.latitude - latitudeDelta / 2
        let maximumLatitude = center.latitude + latitudeDelta / 2
        let minimumLongitude = center.longitude - longitudeDelta / 2
        let maximumLongitude = center.longitude + longitudeDelta / 2
        let otherMinimumLatitude = other.center.latitude - other.latitudeDelta / 2
        let otherMaximumLatitude = other.center.latitude + other.latitudeDelta / 2
        let otherMinimumLongitude = other.center.longitude - other.longitudeDelta / 2
        let otherMaximumLongitude = other.center.longitude + other.longitudeDelta / 2

        return otherMinimumLatitude >= minimumLatitude &&
            otherMaximumLatitude <= maximumLatitude &&
            otherMinimumLongitude >= minimumLongitude &&
            otherMaximumLongitude <= maximumLongitude
    }
}

/// Cached MapKit presentation data for one cycling path segment.
struct CyclingPathMapPolyline: Identifiable {
    let id: String
    let polyline: MKPolyline
}
