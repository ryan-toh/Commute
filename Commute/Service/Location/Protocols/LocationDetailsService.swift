//
//  LocationDetailsService.swift
//  Commute
//
//  Created by Ryan on 31/8/26.
//

import Foundation

protocol LocationDetailsService {
    func details(for location: Location) async throws -> PlaceDetails
}
