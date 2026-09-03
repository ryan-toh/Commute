//
//  DestinationAnnotation.swift
//  Commute
//
//  Created by Ryan on 28/8/26.
//

import SwiftUI
import MapKit

struct DestinationAnnotation: MapContent {
    // MARK: - Data In
    let location: Location?
    
    var body: some MapContent {
        if let location {
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)) {
                Image(systemName: Preferences.NavigationUI.destinationSymbol)
                    .font(.title)
                    .foregroundStyle(Preferences.NavigationUI.destinationSymbolColor)
                    .symbolEffect(.bounce, options: Preferences.Motion.destinationSymbolEffect, value: location.id)
            }
        }
    }
}
