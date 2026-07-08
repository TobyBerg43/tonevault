import SwiftUI

extension Color {
    /// Warm amp-knob accent. Also defined in the asset catalog as AccentColor;
    /// this constant keeps code paths simple and previewable.
    static let tvAccent = Color(red: 0.88, green: 0.33, blue: 0.22)

    init?(hex: String?) {
        guard let hex, hex.hasPrefix("#"), hex.count == 7,
              let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

/// A small set of preset gear colors the user can pick (generic, no brand palettes).
enum GearColorPreset: String, CaseIterable, Identifiable {
    case red = "#E0533A"
    case orange = "#E08A2E"
    case yellow = "#D8B32A"
    case green = "#3FA65A"
    case teal = "#2FA69A"
    case blue = "#3A72E0"
    case purple = "#7A54E0"
    case pink = "#D0559C"
    case graphite = "#5A5F66"

    var id: String { rawValue }
    var color: Color { Color(hex: rawValue) ?? .gray }
}
