//
//  UserLocationAnnotation.swift
//  Commute
//
//  Created by Ryan on 28/8/26.
//

import SwiftUI
import MapKit

struct UserLocationAnnotation: MapContent {
    // MARK: - Data In
    let location: Location?
    
    var body: some MapContent {
        if let location {
            LocationAnnotation(location: location) { UserLocationStyleView() }
        }
    }
}
