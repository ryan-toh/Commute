import SwiftUI

/// Provides restrained press feedback for controls with custom visual styles.
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.94)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(Preferences.Motion.buttonPressAnimation, value: configuration.isPressed)
    }
}
