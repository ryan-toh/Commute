//
//  StartNavigationButton.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Starts navigation using the planned route.
struct StartNavigationButton: View {
    // MARK: - Data In
    let action: () -> Void

    var body: some View {
        RouteActionButton(
            title: Preferences.NavigationUI.startNavigation,
            symbolName: Preferences.CyclingNavigation.startNavigationSymbol,
            tint: .blue,
            action: action
        )
    }
}
