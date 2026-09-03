//
//  RouteStepView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

/// Displays the cyclist's next required maneuver.
struct RouteStepView: View {
    
    // MARK: - Data In
    let step: RouteStep?
    let distanceToManeuverMeters: Double?

    var body: some View {
        if let step {
            VStack(spacing: Preferences.CyclingNavigation.maneuverSpacing) {
                Image(systemName: symbolName(for: step.maneuver))
                    .font(.system(size: Preferences.CyclingNavigation.maneuverSymbolSize, weight: .bold))
                    .accessibilityHidden(true)

                Text(
                    String(
                        format: Preferences.CyclingNavigation.nextManeuverDistanceFormat,
                        distanceToManeuverMeters ?? step.distanceMeters
                    )
                )
                    .font(.title2.weight(.semibold))

                Text(step.instruction)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func symbolName(for maneuver: RouteManeuver) -> String {
        switch maneuver {
        case .straight: Preferences.CyclingNavigation.straightSymbol
        case .slightLeft: Preferences.CyclingNavigation.slightLeftSymbol
        case .left: Preferences.CyclingNavigation.leftSymbol
        case .sharpLeft: Preferences.CyclingNavigation.sharpLeftSymbol
        case .slightRight: Preferences.CyclingNavigation.slightRightSymbol
        case .right: Preferences.CyclingNavigation.rightSymbol
        case .sharpRight: Preferences.CyclingNavigation.sharpRightSymbol
        case .uTurn: Preferences.CyclingNavigation.uTurnSymbol
        case .arrive: Preferences.CyclingNavigation.arriveSymbol
        case .unknown: Preferences.CyclingNavigation.unknownManeuverSymbol
        }
    }
}
