import SwiftUI

/// An on/off switch control. Value is 0 (off) or 1 (on).
struct ToggleControlView: View {
    @Binding var value: Double
    var label: String
    var isEditable: Bool = true

    private var isOn: Binding<Bool> {
        Binding(
            get: { value >= 0.5 },
            set: { newValue in
                value = newValue ? 1 : 0
                Haptics.impact(.light)
            }
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .disabled(!isEditable)
                .tint(.tvAccent)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value >= 0.5 ? "On" : "Off")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 88)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value >= 0.5 ? "On" : "Off")
    }
}
