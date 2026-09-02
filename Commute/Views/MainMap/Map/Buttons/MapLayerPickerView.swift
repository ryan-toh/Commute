import SwiftUI

/// Lets the user select one or more optional map layers.
struct MapLayerPickerView: View {
    let enabledLayers: Set<MapLayer>
    let isSatelliteStyleEnabled: Bool
    let onLayerEnabledChanged: (MapLayer, Bool) -> Void
    let onSatelliteStyleEnabledChanged: (Bool) -> Void
    @State private var isExpanded = false

    private let selectableLayers: [MapLayer] = [
        .cyclingPaths,
        .userLocation
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            layerArc
            pickerButton
        }
        .animation(Preferences.MapLayers.pickerLayerAnimation, value: isExpanded)
    }

    private var pickerButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            Image(systemName: Preferences.MapLayers.pickerSymbol)
                .font(.system(size: Preferences.MapLayers.pickerSymbolSize))
                .bold()
                .padding(Preferences.NavigationUI.recenterButtonContentPadding)
                .liquidGlassSurface(in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Preferences.MapLayers.pickerAccessibilityLabel)
        .accessibilityHint(
            isExpanded
                ? Preferences.MapLayers.pickerCollapseAccessibilityHint
                : Preferences.MapLayers.pickerExpansionAccessibilityHint
        )
    }

    private var layerArc: some View {
        Group {
            layerButton(for: selectableLayers[0])
                .arcPresentation(isExpanded: isExpanded, at: 0)
            satelliteButton
                .arcPresentation(isExpanded: isExpanded, at: 1)
            layerButton(for: selectableLayers[1])
                .arcPresentation(isExpanded: isExpanded, at: 2)
        }
    }

    private var satelliteButton: some View {
        Button {
            onSatelliteStyleEnabledChanged(!isSatelliteStyleEnabled)
        } label: {
            Image(
                systemName: isSatelliteStyleEnabled
                    ? Preferences.MapLayers.standardMapSymbol
                    : Preferences.MapLayers.satelliteSymbol
            )
                .font(.system(size: Preferences.MapLayers.pickerLayerSymbolSize, weight: .semibold))
                .frame(
                    width: Preferences.MapLayers.pickerLayerControlSize,
                    height: Preferences.MapLayers.pickerLayerControlSize
                )
                .liquidGlassSurface(in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(
            isSatelliteStyleEnabled
                ? Preferences.MapLayers.standardMapAccessibilityLabel
                : Preferences.MapLayers.satelliteAccessibilityLabel
        )
        .accessibilityValue(
            isSatelliteStyleEnabled
                ? Preferences.MapLayers.layerShownAccessibilityValue
                : Preferences.MapLayers.layerHiddenAccessibilityValue
        )
        .accessibilityHint(
            isSatelliteStyleEnabled
                ? Preferences.MapLayers.satelliteDisableAccessibilityHint
                : Preferences.MapLayers.satelliteEnableAccessibilityHint
        )
    }

    private func layerButton(for layer: MapLayer) -> some View {
        let isEnabled = enabledLayers.contains(layer)
        return Button {
            onLayerEnabledChanged(layer, !isEnabled)
        } label: {
            Image(systemName: Preferences.MapLayers.symbol(for: layer))
                .font(.system(size: Preferences.MapLayers.pickerLayerSymbolSize, weight: .semibold))
                .symbolVariant(isEnabled ? .fill : .none)
                .frame(
                    width: Preferences.MapLayers.pickerLayerControlSize,
                    height: Preferences.MapLayers.pickerLayerControlSize
                )
                .liquidGlassSurface(in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Preferences.MapLayers.title(for: layer))
        .accessibilityValue(
            isEnabled
                ? Preferences.MapLayers.layerShownAccessibilityValue
                : Preferences.MapLayers.layerHiddenAccessibilityValue
        )
        .accessibilityHint(
            isEnabled
                ? Preferences.MapLayers.layerHideAccessibilityHint
                : Preferences.MapLayers.layerShowAccessibilityHint
        )
    }

}

private extension View {
    func arcPresentation(isExpanded: Bool, at index: Int) -> some View {
        offset(isExpanded ? Preferences.MapLayers.pickerArcOffsets[index] : .zero)
            .scaleEffect(isExpanded ? 1 : Preferences.MapLayers.pickerCollapsedScale)
            .opacity(isExpanded ? 1 : 0)
            .allowsHitTesting(isExpanded)
    }
}
