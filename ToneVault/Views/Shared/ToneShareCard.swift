import SwiftUI

/// A clean, self-contained image card of one saved tone, for sharing.
/// Rendered off-screen with ImageRenderer; always dark, always 360pt wide.
struct ToneShareCard: View {
    let setting: ToneSetting
    let style: KnobDisplayStyle

    private var accent: Color {
        Color(hex: setting.gear?.brandColorHex) ?? Color.tvAccent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 10) {
                Circle().fill(accent).frame(width: 14, height: 14)
                Text(setting.gear?.name ?? "Gear")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            Text(setting.name.isEmpty ? "Untitled tone" : setting.name)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            // Controls
            let values = setting.sortedControlValues
            let columns = [GridItem(.adaptive(minimum: 74), spacing: 14)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                ForEach(values) { cv in
                    controlCell(cv)
                }
            }

            // Footer
            HStack {
                Image(systemName: "dial.medium.fill")
                    .foregroundStyle(Color.tvAccent)
                Text("Saved with ToneVault")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(
            LinearGradient(colors: [Color(red: 0.13, green: 0.13, blue: 0.15),
                                    Color(red: 0.06, green: 0.06, blue: 0.08)],
                           startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    @ViewBuilder
    private func controlCell(_ cv: ControlValue) -> some View {
        let spec = setting.gear?.controls.first { $0.id == cv.controlIndex }
        VStack(spacing: 6) {
            switch cv.kind {
            case .knob:
                MiniDial(fraction: cv.value / 10.0, accent: accent)
                    .frame(width: 54, height: 54)
            case .slider:
                MiniBar(fraction: cv.value / 100.0, accent: accent)
                    .frame(width: 54, height: 54)
            case .toggle:
                Image(systemName: cv.value >= 0.5 ? "power.circle.fill" : "power.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(cv.value >= 0.5 ? accent : Color.white.opacity(0.25))
                    .frame(width: 54, height: 54)
            case .selector:
                MiniDial(fraction: fractionForSelector(cv, spec: spec), accent: accent)
                    .frame(width: 54, height: 54)
            }
            Text(cv.label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
            Text(ControlValueFormatter.string(for: cv.value, kind: cv.kind, style: style,
                                              selectorPositions: spec?.selectorPositions ?? 3))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 74)
    }

    private func fractionForSelector(_ cv: ControlValue, spec: ControlSpec?) -> Double {
        let positions = max((spec?.selectorPositions ?? 3) - 1, 1)
        return min(max(cv.value / Double(positions), 0), 1)
    }
}

/// Static rotary dial: 270° track, filled arc, pointer. No interaction.
private struct MiniDial: View {
    let fraction: Double // 0...1
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: 0.75 * min(max(fraction, 0), 1))
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(135))
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2 - 8
                let angle = -135.0 + min(max(fraction, 0), 1) * 270.0
                Path { p in
                    p.move(to: center)
                    let rad = Angle(degrees: angle - 90).radians
                    p.addLine(to: CGPoint(x: center.x + CGFloat(cos(rad)) * radius,
                                          y: center.y + CGFloat(sin(rad)) * radius))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            .padding(6)
        }
    }
}

/// Static vertical fader bar.
private struct MiniBar: View {
    let fraction: Double // 0...1
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 6)
                Capsule()
                    .fill(accent)
                    .frame(width: 6, height: geo.size.height * min(max(fraction, 0), 1))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Renders the card to a UIImage for the share sheet.
enum ToneCardRenderer {
    @MainActor
    static func render(setting: ToneSetting, style: KnobDisplayStyle) -> UIImage? {
        let renderer = ImageRenderer(content: ToneShareCard(setting: setting, style: style))
        renderer.scale = 3
        return renderer.uiImage
    }
}

#if DEBUG
#Preview {
    let context = PreviewData.container.mainContext
    let setting = try! context.fetch(.init(predicate: #Predicate<ToneSetting> { _ in true })).first!
    return ToneShareCard(setting: setting, style: .numeric)
        .padding()
}
#endif
