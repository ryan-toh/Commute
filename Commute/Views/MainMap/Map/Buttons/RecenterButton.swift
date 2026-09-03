//
//  RecenterButtonView.swift
//  Commute
//
//  Created by Ryan on 28/8/26.
//

import SwiftUI

struct RecenterButton: View {
    // MARK: - Data In
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: Preferences.NavigationUI.recenterSymbol)
                .font(.system(size: Preferences.NavigationUI.recenterButtonSymbolSize, weight: .semibold))
                .padding(Preferences.NavigationUI.recenterButtonContentPadding)
                .liquidGlassSurface(in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    RecenterButton {}
}
