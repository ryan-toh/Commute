import SwiftUI

private struct LiquidGlassSurfaceModifier<Shape: SwiftUI.Shape>: ViewModifier {
    let shape: Shape

    func body(content: Content) -> some View {
        content
            .contentShape(shape)
            .glassEffect(.regular.interactive(), in: shape)
    }
}

extension View {
    func liquidGlassSurface() -> some View {
        modifier(LiquidGlassSurfaceModifier(shape: Capsule()))
    }

    func liquidGlassSurface(in shape: some SwiftUI.Shape) -> some View {
        modifier(LiquidGlassSurfaceModifier(shape: shape))
    }
}
