import SwiftUI

/// A rotary selector / multi-way switch. Value is 0...(positions-1), integer-valued.
struct SelectorControlView: View {
    @Binding var value: Double
    var label: String
    var positions: Int
    var isEditable: Bool = true

    private var current: Int { min(max(Int(value.rounded()), 0), max(positions - 1, 0)) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 3)
                    .frame(width: 84, height: 84)

                // Position dots around the dial
                ForEach(0..<max(positions, 1), id: \.self) { i in
                    let a = angle(for: i)
                    Circle()
                        .fill(i == current ? Color.tvAccent : Color.secondary.opacity(0.35))
                        .frame(width: i == current ? 12 : 8, height: i == current ? 12 : 8)
                        .offset(dotOffset(a, radius: 42))
                }

                // Center pointer
                Path { path in
                    let rad = Angle(degrees: angle(for: current) - 90).radians
                    path.move(to: CGPoint(x: 42, y: 42))
                    path.addLine(to: CGPoint(x: 42 + cos(rad) * 26, y: 42 + sin(rad) * 26))
                }
                .stroke(Color.tvAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 84, height: 84)
            }
            .frame(width: 84, height: 84)
            .contentShape(Circle())
            .onTapGesture {
                guard isEditable else { return }
                advance()
            }
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue("Position \(current + 1) of \(positions)")
            .accessibilityAdjustableAction { direction in
                guard isEditable else { return }
                switch direction {
                case .increment: setPosition(current + 1)
                case .decrement: setPosition(current - 1)
                default: break
                }
            }

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Pos \(current + 1) of \(positions)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
    }

    private func advance() {
        let next = (current + 1) % max(positions, 1)
        setPosition(next)
    }

    private func setPosition(_ p: Int) {
        let clamped = min(max(p, 0), max(positions - 1, 0))
        value = Double(clamped)
        Haptics.selection()
    }

    private func angle(for index: Int) -> Double {
        guard positions > 1 else { return -135 }
        let sweep = 270.0
        return -135 + (Double(index) / Double(positions - 1)) * sweep
    }

    private func dotOffset(_ deg: Double, radius: CGFloat) -> CGSize {
        let rad = Angle(degrees: deg - 90).radians
        return CGSize(width: cos(rad) * radius, height: sin(rad) * radius)
    }
}
