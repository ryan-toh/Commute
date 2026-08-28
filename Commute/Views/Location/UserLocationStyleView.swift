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
                .fill(.blue.opacity(0.18))
                .frame(
                    width: min(dotSize * Preferences.UserLocationMarker.haloScale,
                               Preferences.UserLocationMarker.maximumHaloSize),
                    height: min(dotSize * Preferences.UserLocationMarker.haloScale,
                                Preferences.UserLocationMarker.maximumHaloSize)
                )

            Circle()
                .fill(.blue)
                .frame(
                    width: min(dotSize, Preferences.UserLocationMarker.maximumDotSize),
                    height: min(dotSize, Preferences.UserLocationMarker.maximumDotSize)
                )
                .overlay {
                    Circle().stroke(.white, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.25), radius: 2)
        }
    }
}

#Preview {
    UserLocationStyleView()
}
