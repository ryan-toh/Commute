//
//  RouteProgressCalculatorService.swift
//  Commute
//
//  Created by Ryan on 29/8/26.
//

import Foundation

protocol RouteProgressCalculatorService {
    func progress(
        on route: Route,
        at location: Location,
        after routeCoordinatePosition: Double?
    ) -> RouteProgress?
}

