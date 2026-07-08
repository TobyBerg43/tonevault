import SwiftUI

/// A tactile, draggable rotary knob. Drag up/down (or in a circular motion) to turn it.
/// Value range is 0...10. Rotates across a 270° sweep like a real guitar pot.
struct KnobView: View {
    @Binding var value: Double          // 0...10
    var label: String
    var displayStyle: KnobDisplayStyle
    var isEditable: Bool = true
    var diameter: CGFloat = 84

    private let minValue = 0.0
    private let maxValue = 10.0
    private let sweep = 270.0            // degrees
    private let startAngle = -135.0      // degrees (min)

    @State private var dragStartValue: Double?
    @State private var lastHapticStep: Int = -1

    private var angle: Double {
        let fraction = (value - minValue) / (maxValue - minValue)
        return startAngle + fraction * sweep
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Track arc
                Circle()
                    .trim(from: 0.0, to: sweep / 360.0)
                    .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135)) // align gap at bottom

                // Filled progress arc
                Circle()
                    .trim(from: 0.0, to: (sweep / 360.0) * ((value - minValue) / (maxValue - minValue)))
                    .stroke(Color.tvAccent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Knob body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray4), Color(.systemGray6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 1))
                    .padding(12)
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)

                // Pointer / indicator line
                GeometryReader { geo in
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let radius = min(geo.size.width, geo.size.height) / 2 - 14
                    Path { path in
                        path.move(to: center)
                        let rad = Angle(degrees: angle - 90).radians
                        path.addLine(to: CGPoint(
                            x: center.x + CGFloat(cos(rad)) * radius,
                            y: center.y + CGFloat(sin(rad)) * radius
                        ))
                    }
                    .stroke(Color.tvAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .padding(12)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .gestureIf(isEditable, dragGesture)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(ControlValueFormatter.string(for: value, kind: .knob, style: displayStyle))
            .accessibilityAdjustableAction { direction in
                guard isEditable else { return }
                switch direction {
                case .increment: setValue(value + 0.5)
                case .decrement: setValue(value - 0.5)
                default: break
                }
            }

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(ControlValueFormatter.string(for: value, kind: .knob, style: displayStyle))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if dragStartValue == nil { dragStartValue = value }
                // Vertical drag: up increases. Full-range travel over ~180 pts.
                let sensitivity = (maxValue - minValue) / 180.0
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
            let step = Int((clamped * 2).rounded()) // half-unit detents
            if step != lastHapticStep {
                lastHapticStep = step
                Haptics.selection()
            }
        }
    }
}

#if DEBUG
#Preview {
    struct Wrap: View {
        @State var v = 6.5
        var body: some View {
            KnobView(value: $v, label: "Drive", displayStyle: .numeric)
                .padding()
        }
    }
    return Wrap()
}
#endif
