//
//  RoutePlanningProgressView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Indicates that route planning is in progress.
struct RoutePlanningProgressView: View {
    var body: some View {
        ProgressView(Preferences.NavigationUI.planningRoute)
    }
}
