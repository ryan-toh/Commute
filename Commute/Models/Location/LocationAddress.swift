//
//  LocationAddress.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

struct LocationAddress: Codable, Hashable {
    var formatted: String?
    var street: String?
    var district: String?
    var city: String?
    var postalCode: String?
    var country: String?
}
