//
//  RouteActionButton.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Presents a prominent route action with sizing that adapts to available width.
struct RouteActionButton: View {
    // MARK: - Data In
    let title: String
    let symbolName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                label(font: .largeTitle)
                label(font: .title)
                label(font: .headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Preferences.CyclingNavigation.endNavigationVerticalPadding)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
    }

    private func label(font: Font) -> some View {
        Label(title, systemImage: symbolName)
            .font(font.weight(.semibold))
            .lineLimit(1)
    }
}
