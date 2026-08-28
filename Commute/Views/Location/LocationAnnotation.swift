//
//  UserLocation.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI
import MapKit

struct LocationAnnotation<Content: View>: MapContent {
    var location: Location
    let content: Content

    init(
        location: Location,
        @ViewBuilder content: () -> Content
    ) {
        self.location = location
        self.content = content()
    }
    
    var body: some MapContent {
        Annotation(
            "",
            coordinate: CLLocationCoordinate2D(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        ) {
            content
        }
    }
}
