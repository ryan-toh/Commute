//
//  LocationSource.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

enum LocationSource: Codable, Hashable {
    case gps
    case search
    case mapSelection
    case imported
    case unknown
}


