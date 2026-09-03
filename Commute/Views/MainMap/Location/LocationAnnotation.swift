//
//  LocationAnnotation.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI
import MapKit

/// Customisable LocationAnnotation using Location (not CLLocationCoordinate2D)
struct LocationAnnotation<Content: View>: MapContent {
    var location: Location
    @ViewBuilder let content: () -> Content

    init(
        location: Location,
        content: @escaping () -> Content
    ) {
        self.location = location
        self.content = content
    }
    
    var body: some MapContent {
        Annotation(
            "",
            coordinate: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        ) {
            content()
        }
    }
}
