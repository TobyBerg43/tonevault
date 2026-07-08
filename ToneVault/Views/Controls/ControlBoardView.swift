import SwiftUI

/// Lays out all controls for a ToneSetting and binds each to its stored value.
/// Used both in the editor (isEditable = true) and read-only recall/stage views.
struct ControlBoardView: View {
    var controlValues: [ControlValue]
    var specs: [ControlSpec]
    var displayStyle: KnobDisplayStyle
    var isEditable: Bool = true
    /// Larger sizing for the stage/gig view.
    var stageMode: Bool = false

    private func spec(for cv: ControlValue) -> ControlSpec? {
        specs.first { $0.id == cv.controlIndex }
    }

    private func binding(for cv: ControlValue) -> Binding<Double> {
        Binding(get: { cv.value }, set: { cv.value = $0 })
    }

    private var sortedValues: [ControlValue] {
        controlValues.sorted { $0.controlIndex < $1.controlIndex }
    }

    private var allSliders: Bool {
        !sortedValues.isEmpty && sortedValues.allSatisfy { $0.kind == .slider }
    }

    var body: some View {
        if allSliders {
            // Graphic EQ: horizontal row of faders, scrollable if many bands.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: stageMode ? 20 : 12) {
                    ForEach(sortedValues) { cv in
                        SliderControlView(
                            value: binding(for: cv),
                            label: cv.label,
                            isEditable: isEditable,
                            height: stageMode ? 160 : 120
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        } else {
            let columns = [GridItem(.adaptive(minimum: stageMode ? 120 : 96), spacing: 16)]
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(sortedValues) { cv in
                    control(for: cv)
                }
            }
        }
    }

    @ViewBuilder
    private func control(for cv: ControlValue) -> some View {
        switch cv.kind {
        case .knob:
            KnobView(
                value: binding(for: cv),
                label: cv.label,
                displayStyle: displayStyle,
                isEditable: isEditable,
                diameter: stageMode ? 104 : 84
            )
        case .slider:
            SliderControlView(value: binding(for: cv), label: cv.label, isEditable: isEditable)
        case .toggle:
            ToggleControlView(value: binding(for: cv), label: cv.label, isEditable: isEditable)
        case .selector:
            SelectorControlView(
                value: binding(for: cv),
                label: cv.label,
                positions: spec(for: cv)?.selectorPositions ?? 3,
                isEditable: isEditable
            )
        }
    }
}
