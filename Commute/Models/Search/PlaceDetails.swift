//
//  PlaceDetails.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import Foundation

struct PlaceDetails: Hashable {
    let name: String
    let address: String?
    let categoryName: String?
    let phoneNumber: String?
    let websiteURL: URL?

    init(location: Location) {
        name = location.name ?? Preferences.NavigationUI.selectedDestinationName
        address = location.address?.formatted
        categoryName = nil
        phoneNumber = nil
        websiteURL = nil
    }

    init(
        name: String,
        address: String?,
        categoryName: String?,
        phoneNumber: String?,
        websiteURL: URL?
    ) {
        self.name = name
        self.address = address
        self.categoryName = categoryName
        self.phoneNumber = phoneNumber
        self.websiteURL = websiteURL
    }

    var callURL: URL? {
        guard let phoneNumber else { return nil }
        let dialableNumber = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(dialableNumber)")
    }
}
