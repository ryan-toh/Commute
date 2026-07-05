//
//  BikeParkingDataModel.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import Foundation
import SwiftData

@Model
class BikeParkingLocation {
    var type: String
    var properties: BikeParkingProperties
    var coordinate: BikeParkingCoordinate

    init(type: String, properties: BikeParkingProperties, coordinate: BikeParkingCoordinate) {
        self.type = type
        self.properties = properties
        self.coordinate = coordinate
    }
}

@Model
class BikeParkingProperties {
    var name: String
    var descriptionText: String
    
    init(name: String, descriptionText: String) {
        self.name = name
        self.descriptionText = descriptionText
    }
}

@Model
class BikeParkingCoordinate {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
