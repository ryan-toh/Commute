import CoreLocation
import MapKit

final class MapKitDestinationSearchService: DestinationSearchService {
    func searchDestinations(
        matching query: String,
        in area: LocationSearchArea?
    ) async throws -> [Location] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        if let area {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: area.center.latitude,
                    longitude: area.center.longitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: area.latitudeDelta,
                    longitudeDelta: area.longitudeDelta
                )
            )
        }

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap(makeLocation(from:))
    }

    private func makeLocation(from mapItem: MKMapItem) -> Location? {
        let coordinate = mapItem.location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }

        return Location(
            id: UUID(),
            coordinate: LocationCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            address: makeAddress(from: mapItem),
            name: mapItem.name,
            source: .search,
            capturedAt: .now
        )
    }

    private func makeAddress(from mapItem: MKMapItem) -> LocationAddress? {
        let address = mapItem.address
        let representations = mapItem.addressRepresentations
        guard address != nil || representations != nil else { return nil }

        return LocationAddress(
            formatted: representations?.fullAddress(includingRegion: true, singleLine: true) ?? address?.fullAddress,
            street: address?.shortAddress,
            district: nil,
            city: representations?.cityName,
            postalCode: nil,
            country: representations?.regionName
        )
    }
}
