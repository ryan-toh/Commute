//
//  BikeParkingCollection.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import Foundation
import SwiftData

// For internal noting: if you want to change the name of a JSON entry, include an enum of coding keys.
//struct ToDo: Decodable {
//  let userId: Int
//  let id: Int
//  let title: String
//  let isComplete: Bool
//  
//  enum CodingKeys: String, CodingKey {
//    case isComplete = "completed"
//    case userId, id, title
//  }
//}

struct BikeParkingJsonModel: Codable {
    let type: String
    let crs: CRS
    let features: [Feature]
}

struct CRS: Codable {
    let type: String
    let properties: CRSProperties
}

struct CRSProperties: Codable {
    let name: String
}

struct Feature: Codable {
    let type: String
    let properties: FeatureProperties
    let geometry: Geometry
    
    func toBikeParkingLocation() -> BikeParkingLocation {
        return BikeParkingLocation(
            type: self.type,
            properties:
                BikeParkingProperties(
                    name: self.properties.name,
                    descriptionText: self.properties.description
                ),
            coordinate:
                BikeParkingCoordinate(
                    latitude: self.geometry.coordinates[1],
                    longitude: self.geometry.coordinates[0]
                )
        )
    }
}

struct FeatureProperties: Codable {
    let name: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case description = "Description"
    }
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}
