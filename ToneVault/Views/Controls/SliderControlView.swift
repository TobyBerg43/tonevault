import SwiftUI

/// A vertical fader for graphic-EQ style controls. Value range 0...100 (%).
struct SliderControlView: View {
    @Binding var value: Double        // 0...100
    var label: String
    var isEditable: Bool = true
    var height: CGFloat = 120

    private let minValue = 0.0
    private let maxValue = 100.0
    @State private var dragStartValue: Double?
    @State private var lastHapticStep = -1

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let trackHeight = geo.size.height
                let fraction = CGFloat((value - minValue) / (maxValue - minValue))
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 6)
                    Capsule()
                        .fill(Color.tvAccent)
                        .frame(width: 6, height: trackHeight * fraction)
                    // Cap / thumb
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.15)))
                        .frame(width: 34, height: 16)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                        .offset(y: -(trackHeight - 16) * fraction)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gestureIf(isEditable, drag(trackHeight: trackHeight))
            }
            .frame(width: 44, height: height)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value.rounded())) percent")
            .accessibilityAdjustableAction { direction in
                guard isEditable else { return }
                switch direction {
                case .increment: setValue(value + 5)
                case .decrement: setValue(value - 5)
                default: break
                }
            }

            Text(label)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 48)
            Text("\(Int(value.rounded()))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func drag(trackHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if dragStartValue == nil { dragStartValue = value }
                let sensitivity = (maxValue - minValue) / Double(trackHeight)
                let delta = -g.translation.height * sensitivity
                setValue((dragStartValue ?? value) + delta, haptic: true)
            }
            .onEnded { _ in
                dragStartValue = nil
                lastHapticStep = -1
            }
    }

    private func setValue(_ newValue: Double, haptic: Bool = false) {
        let clamped = min(max(newValue, minValue), maxValue)
        value = clamped
        if haptic {
            let step = Int((clamped / 5).rounded())
            if step != lastHapticStep {
                lastHapticStep = step
                Haptics.selection()
            }
        }
    }
}
