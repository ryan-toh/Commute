import SwiftUI
import MapKit

struct RouteLine: MapContent {
    let route: Route?
    let progress: RouteProgress?

    var body: some MapContent {
        if let route {
            let routeCoordinates = route.coordinates.map(mapCoordinate(from:))

            if let progress {
                let segments = split(routeCoordinates, at: progress.routeCoordinatePosition)

                if segments.completed.count > 1 {
                    MapPolyline(coordinates: segments.completed)
                        .stroke(
                            Preferences.NavigationUI.completedRouteLineOutlineColor,
                            lineWidth: Preferences.NavigationUI.routeLineOutlineWidth
                        )
                    MapPolyline(coordinates: segments.completed)
                        .stroke(
                            Preferences.NavigationUI.completedRouteLineColor,
                            lineWidth: Preferences.NavigationUI.routeLineWidth
                        )
                }

                if segments.remaining.count > 1 {
                    MapPolyline(coordinates: segments.remaining)
                        .stroke(
                            Preferences.NavigationUI.remainingRouteLineOutlineColor,
                            lineWidth: Preferences.NavigationUI.routeLineOutlineWidth
                        )
                    MapPolyline(coordinates: segments.remaining)
                        .stroke(
                            Preferences.NavigationUI.remainingRouteLineColor,
                            lineWidth: Preferences.NavigationUI.routeLineWidth
                        )
                }
            } else {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(
                        Preferences.NavigationUI.remainingRouteLineOutlineColor,
                        lineWidth: Preferences.NavigationUI.routeLineOutlineWidth
                    )
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(
                        Preferences.NavigationUI.remainingRouteLineColor,
                        lineWidth: Preferences.NavigationUI.routeLineWidth
                    )
            }

            if let startCoordinate = routeCoordinates.first {
                RouteEndpointMarker(
                    coordinate: startCoordinate,
                    symbolName: Preferences.NavigationUI.routeStartSymbol,
                    color: Preferences.NavigationUI.routeStartMarkerColor,
                    accessibilityLabel: Preferences.NavigationUI.routeStartAccessibilityLabel
                )
            }

            if let endCoordinate = routeCoordinates.last {
                RouteEndpointMarker(
                    coordinate: endCoordinate,
                    symbolName: Preferences.NavigationUI.routeEndSymbol,
                    color: Preferences.NavigationUI.routeEndMarkerColor,
                    accessibilityLabel: Preferences.NavigationUI.routeEndAccessibilityLabel
                )
            }
        }
    }

    private func split(
        _ coordinates: [CLLocationCoordinate2D],
        at routeCoordinatePosition: Double
    ) -> (completed: [CLLocationCoordinate2D], remaining: [CLLocationCoordinate2D]) {
        guard coordinates.count > 1 else { return (coordinates, []) }

        let clampedPosition = min(
            max(routeCoordinatePosition, 0),
            Double(coordinates.count - 1)
        )
        let lowerIndex = Int(clampedPosition.rounded(.down))
        let fraction = clampedPosition - Double(lowerIndex)

        if fraction == 0 {
            return (
                Array(coordinates[...lowerIndex]),
                Array(coordinates[lowerIndex...])
            )
        }

        let start = coordinates[lowerIndex]
        let end = coordinates[lowerIndex + 1]
        let splitCoordinate = CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )

        return (
            Array(coordinates[...lowerIndex]) + [splitCoordinate],
            [splitCoordinate] + Array(coordinates[(lowerIndex + 1)...])
        )
    }

    private func mapCoordinate(from coordinate: LocationCoordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

private struct RouteEndpointMarker: MapContent {
    let coordinate: CLLocationCoordinate2D
    let symbolName: String
    let color: Color
    let accessibilityLabel: String

    var body: some MapContent {
        Annotation(accessibilityLabel, coordinate: coordinate) {
            Image(systemName: symbolName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(
                    width: Preferences.NavigationUI.routeEndpointMarkerSize,
                    height: Preferences.NavigationUI.routeEndpointMarkerSize
                )
                .background(color, in: Circle())
                .overlay {
                    Circle().stroke(
                        Preferences.NavigationUI.routeEndpointMarkerBorderColor,
                        lineWidth: Preferences.NavigationUI.routeEndpointMarkerBorderWidth
                    )
                }
                .shadow(radius: Preferences.NavigationUI.routeEndpointMarkerShadowRadius)
        }
    }
}
