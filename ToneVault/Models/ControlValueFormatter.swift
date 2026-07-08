import Foundation

/// Formats a control value into a human-readable string for the UI and exports.
enum ControlValueFormatter {

    /// e.g. "7.5", "2 o'clock", "68%", "On", "Pos 3"
    static func string(for value: Double, kind: ControlKind, style: KnobDisplayStyle, selectorPositions: Int = 3) -> String {
        switch kind {
        case .knob:
            switch style {
            case .numeric:
                return numeric(value)
            case .clock:
                return clock(for: value)
            }
        case .slider:
            return "\(Int(value.rounded()))%"
        case .toggle:
            return value >= 0.5 ? "On" : "Off"
        case .selector:
            return "Pos \(Int(value.rounded()) + 1) of \(max(selectorPositions, 1))"
        }
    }

    static func numeric(_ value: Double) -> String {
        // One decimal, but drop a trailing .0
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    /// Maps a 0...10 knob to a guitar-amp style clock sweep (7 o'clock → 5 o'clock).
    static func clock(for value: Double) -> String {
        let clamped = min(max(value, 0), 10)
        // 0 -> 7 o'clock, 10 -> 5 o'clock, sweeping clockwise through 12.
        // Hours sequence across the sweep: 7,8,9,10,11,12,1,2,3,4,5  (11 stops)
        let stops = [7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5]
        let idx = Int((clamped / 10.0 * Double(stops.count - 1)).rounded())
        let hour = stops[min(max(idx, 0), stops.count - 1)]
        return "\(hour) o'clock"
    }
}
