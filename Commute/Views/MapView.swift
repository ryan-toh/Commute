//
//  MapView.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import SwiftUI
import MapKit
import GeoToolbox

struct MapView: View {
    var body: some View {
        Map {
            Marker("Example", coordinate: annaLiviaCoordinates)
        }
    }
    
    let annaLiviaCoordinates = CLLocationCoordinate2D(
        latitude: 53.347673,
        longitude: -6.290198
    )
}


#Preview {
    MapView()
}
