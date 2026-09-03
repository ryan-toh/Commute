//
//  PlanRouteButton.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Starts route planning for a selected destination.
struct PlanRouteButton: View {
    // MARK: - Data In
    let action: () -> Void

    var body: some View {
        RouteActionButton(
            title: Preferences.NavigationUI.planRoute,
            symbolName: Preferences.CyclingNavigation.planRouteSymbol,
            tint: .blue,
            action: action
        )
    }
}
