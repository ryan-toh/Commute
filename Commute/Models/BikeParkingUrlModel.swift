//
//  BikeParkingUrlModel.swift
//  Commute
//
//  Created by Ryan on 4/7/26.
//

import Foundation

struct BikeParkingUrlModel: Codable {
    let code: Int
    let data: BikeParkingUrl
    let errorMsg: String
}

struct BikeParkingUrl: Codable {
    let url: URL
}
