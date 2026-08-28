//
//  UserLocationStyleView.swift
//  Commute
//
//  Created by Ryan on 26/8/26.
//

import SwiftUI

struct UserLocationStyleView: View {
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
    }
}

#Preview {
    UserLocationStyleView()
}
