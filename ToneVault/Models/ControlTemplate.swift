import Foundation

/// The kind of a single control on a piece of gear.
enum ControlKind: String, Codable, Hashable, Sendable {
    case knob        // rotary pot, 0...10 (or clock positions for display)
    case slider      // vertical fader, 0...100 %
    case toggle      // on / off switch
    case selector    // rotary selector / multi-way switch (discrete positions)
}

/// A single control's definition within a template (label + kind + options).
struct ControlSpec: Codable, Hashable, Identifiable, Sendable {
    var id: Int              // stable index within the template
    var label: String        // e.g. "Drive", "Tone", "Level", "Bass"
    var kind: ControlKind
    /// For `.selector` only: the number of discrete positions (e.g. 3-way = 3).
    var selectorPositions: Int

    init(id: Int, label: String, kind: ControlKind, selectorPositions: Int = 3) {
        self.id = id
        self.label = label
        self.kind = kind
        self.selectorPositions = selectorPositions
    }
}

/// The generic, reusable control layouts ToneVault ships.
/// NOTE: entirely generic — no manufacturer names, models, logos, or trademarked artwork.
/// The user names their gear themselves.
enum ControlTemplate: String, Codable, CaseIterable, Identifiable, Sendable {
    case threeKnob        // Drive / Tone / Level
    case fourKnob
    case fiveKnob
    case sixKnob
    case ampHead          // Gain / Bass / Mid / Treble / Presence / Master
    case eqThreeBand      // Bass / Mid / Treble knobs
    case graphicEQ5       // 5-band sliders
    case graphicEQ7       // 7-band sliders
    case graphicEQ10      // 10-band sliders
    case rotarySwitch     // single multi-way rotary selector
    case toggleRow        // a row of toggle switches
    case miniPotRow       // a row of small knobs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .threeKnob:   return "3-Knob (Drive / Tone / Level)"
        case .fourKnob:    return "4-Knob"
        case .fiveKnob:    return "5-Knob"
        case .sixKnob:     return "6-Knob"
        case .ampHead:     return "Amp Head (Gain / Bass / Mid / Treble / Presence / Master)"
        case .eqThreeBand: return "3-Band EQ"
        case .graphicEQ5:  return "Graphic EQ — 5 Band"
        case .graphicEQ7:  return "Graphic EQ — 7 Band"
        case .graphicEQ10: return "Graphic EQ — 10 Band"
        case .rotarySwitch: return "Rotary Switch"
        case .toggleRow:   return "Toggle Switches"
        case .miniPotRow:  return "Mini-Pot Row"
        }
    }

    var shortName: String {
        switch self {
        case .threeKnob: return "3-Knob"
        case .fourKnob: return "4-Knob"
        case .fiveKnob: return "5-Knob"
        case .sixKnob: return "6-Knob"
        case .ampHead: return "Amp Head"
        case .eqThreeBand: return "3-Band EQ"
        case .graphicEQ5: return "EQ 5"
        case .graphicEQ7: return "EQ 7"
        case .graphicEQ10: return "EQ 10"
        case .rotarySwitch: return "Rotary"
        case .toggleRow: return "Toggles"
        case .miniPotRow: return "Mini Pots"
        }
    }

    /// The ordered list of controls this template defines.
    var controls: [ControlSpec] {
        switch self {
        case .threeKnob:
            return knobs(["Drive", "Tone", "Level"])
        case .fourKnob:
            return knobs(["Knob 1", "Knob 2", "Knob 3", "Knob 4"])
        case .fiveKnob:
            return knobs(["Knob 1", "Knob 2", "Knob 3", "Knob 4", "Knob 5"])
        case .sixKnob:
            return knobs(["Knob 1", "Knob 2", "Knob 3", "Knob 4", "Knob 5", "Knob 6"])
        case .ampHead:
            return knobs(["Gain", "Bass", "Mid", "Treble", "Presence", "Master"])
        case .eqThreeBand:
            return knobs(["Bass", "Mid", "Treble"])
        case .graphicEQ5:
            return sliders(["100", "330", "1k", "3.3k", "10k"])
        case .graphicEQ7:
            return sliders(["63", "160", "400", "1k", "2.5k", "6.3k", "16k"])
        case .graphicEQ10:
            return sliders(["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"])
        case .rotarySwitch:
            return [ControlSpec(id: 0, label: "Mode", kind: .selector, selectorPositions: 5)]
        case .toggleRow:
            return [
                ControlSpec(id: 0, label: "Switch 1", kind: .toggle),
                ControlSpec(id: 1, label: "Switch 2", kind: .toggle),
                ControlSpec(id: 2, label: "Switch 3", kind: .toggle)
            ]
        case .miniPotRow:
            return knobs(["Mini 1", "Mini 2", "Mini 3", "Mini 4"])
        }
    }

    /// Default value for a given control, used when creating a fresh setting.
    static func defaultValue(for spec: ControlSpec) -> Double {
        switch spec.kind {
        case .knob:     return 5.0    // 0...10 midpoint
        case .slider:   return 50.0   // 0...100 midpoint
        case .toggle:   return 0.0    // off
        case .selector: return 0.0    // first position
        }
    }

    private func knobs(_ labels: [String]) -> [ControlSpec] {
        labels.enumerated().map { ControlSpec(id: $0.offset, label: $0.element, kind: .knob) }
    }

    private func sliders(_ labels: [String]) -> [ControlSpec] {
        labels.enumerated().map { ControlSpec(id: $0.offset, label: $0.element, kind: .slider) }
    }
}

/// How knob values are shown to the user (their choice, persisted in UserDefaults).
enum KnobDisplayStyle: String, CaseIterable, Identifiable, Sendable {
    case numeric   // 0.0 ... 10.0
    case clock     // 7 o'clock ... 5 o'clock sweep

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .numeric: return "Numbers (0–10)"
        case .clock:   return "Clock positions"
        }
    }
}
