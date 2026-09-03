//
//  NavigationStatusView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Displays a temporary navigation status in place of next-maneuver guidance.
struct NavigationStatusView: View {
    // MARK: - Data In
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let symbolName: String
    let symbolColor: Color
    let showsProgress: Bool
    
    // MARK: - Data owned by Me
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: Preferences.CyclingNavigation.maneuverSpacing) {
            Image(systemName: symbolName)
                .font(.system(size: Preferences.CyclingNavigation.statusSymbolSize, weight: .semibold))
                .foregroundStyle(symbolColor)
                .scaleEffect(reduceMotion || hasAppeared ? 1 : 0.85)
                .opacity(reduceMotion || hasAppeared ? 1 : 0)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(Preferences.CyclingNavigation.statusSymbolAppearAnimation) {
                        hasAppeared = true
                    }
                }

            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            if showsProgress {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
