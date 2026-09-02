//
//  MapKitPlaceDetailsService.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import CoreLocation
import MapKit

final class MapKitPlaceDetailsService: LocationDetailsService {
    func details(for location: Location) async throws -> PlaceDetails {
        guard let name = location.name, !name.isEmpty else {
            return PlaceDetails(location: location)
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.resultTypes = [.pointOfInterest, .address]
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            latitudinalMeters: Preferences.PlaceDetail.searchRadiusMeters,
            longitudinalMeters: Preferences.PlaceDetail.searchRadiusMeters
        )

        let response = try await MKLocalSearch(request: request).start()
        guard let mapItem = nearestMapItem(in: response.mapItems, to: location.coordinate) else {
            return PlaceDetails(location: location)
        }

        return PlaceDetails(
            name: mapItem.name ?? name,
            address: mapItem.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true)
                ?? location.address?.formatted,
            categoryName: mapItem.pointOfInterestCategory?.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
            phoneNumber: mapItem.phoneNumber,
            websiteURL: mapItem.url
        )
    }

    private func nearestMapItem(
        in mapItems: [MKMapItem],
        to coordinate: LocationCoordinate
    ) -> MKMapItem? {
        let tappedLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard let nearestMapItem = mapItems.min(by: { first, second in
            first.location.distance(from: tappedLocation) < second.location.distance(from: tappedLocation)
        }) else {
            return nil
        }

        guard nearestMapItem.location.distance(from: tappedLocation) <= Preferences.PlaceDetail.maximumMapItemDistanceMeters else {
            return nil
        }

        return nearestMapItem
    }
}
