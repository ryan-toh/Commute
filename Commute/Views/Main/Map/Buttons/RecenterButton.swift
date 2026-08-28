//
//  RecenterButtonView.swift
//  Commute
//
//  Created by Ryan on 28/8/26.
//

import SwiftUI

struct RecenterButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: Preferences.NavigationUI.recenterSymbol)
                .font(.title3)
                .padding()
                .background(.regularMaterial, in: Circle())
        }
        .padding()
    }
}

#Preview {
    RecenterButton {
        print("Hello")
    }
}
