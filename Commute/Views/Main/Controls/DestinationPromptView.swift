import SwiftUI

struct DestinationPromptView: View {
    var body: some View {
        Text(Preferences.NavigationUI.destinationPrompt)
            .padding(.horizontal, Preferences.NavigationUI.destinationPromptHorizontalPadding)
            .padding(.vertical, Preferences.NavigationUI.destinationPromptVerticalPadding)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, Preferences.NavigationUI.destinationPromptBottomPadding)
    }
}
