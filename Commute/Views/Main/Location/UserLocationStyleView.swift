//
//  UserLocationStyleView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

struct UserLocationStyleView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHaloPulsing = false
    @ScaledMetric(relativeTo: .body)
    private var dotSize = Preferences.UserLocationMarker.defaultDotSize

    var body: some View {
        ZStack {
            Circle()
                .fill(Preferences.UserLocationMarker.haloColor)
                .frame(
                    width: min(dotSize * Preferences.UserLocationMarker.haloScale,
                               Preferences.UserLocationMarker.maximumHaloSize),
                    height: min(dotSize * Preferences.UserLocationMarker.haloScale,
                                Preferences.UserLocationMarker.maximumHaloSize)
                )
                .scaleEffect(isHaloPulsing ? 1.12 : 1)
                .opacity(isHaloPulsing ? 0.65 : 1)

            Circle()
                .fill(Preferences.UserLocationMarker.dotColor)
                .frame(
                    width: min(dotSize, Preferences.UserLocationMarker.maximumDotSize),
                    height: min(dotSize, Preferences.UserLocationMarker.maximumDotSize)
                )
                .overlay {
                    Circle().stroke(
                        Preferences.UserLocationMarker.borderColor,
                        lineWidth: Preferences.UserLocationMarker.borderWidth
                    )
                }
                .shadow(
                    color: Preferences.UserLocationMarker.shadowColor,
                    radius: Preferences.UserLocationMarker.shadowRadius
                )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Preferences.Motion.locationHaloPulseAnimation) {
                isHaloPulsing = true
            }
        }
    }
}

#Preview {
    UserLocationStyleView()
}
