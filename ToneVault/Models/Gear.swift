import Foundation
import SwiftData

enum GearType: String, Codable, CaseIterable, Identifiable, Sendable {
    case pedal
    case amp
    case multiFX
    case other

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .pedal:   return "Pedal"
        case .amp:     return "Amp"
        case .multiFX: return "Multi-FX"
        case .other:   return "Other"
        }
    }
}

/// A piece of gear the user owns. Defines the control layout; names are user-entered.
///
/// CloudKit-compatible on purpose: every stored property has a default value and all
/// relationships are optional, so this model could later back an optional iCloud sync
/// without a migration. (Sync is NOT enabled in this build.)
@Model
final class Gear {
    var id: UUID = UUID()
    var name: String = ""
    /// Persisted as the enum raw value for portability/CloudKit friendliness.
    var typeRaw: String = GearType.pedal.rawValue
    var templateRaw: String = ControlTemplate.threeKnob.rawValue
    /// Optional custom labels the user typed to override the template's default labels,
    /// keyed by control id. Stored as JSON in a String to stay CloudKit-simple.
    var customLabelsJSON: String = "{}"
    /// A simple accent color hex (e.g. "#E0533A") OR nil. Photo is stored separately as a file.
    var brandColorHex: String?
    var photoFilename: String?
    var notes: String = ""
    var dateCreated: Date = Date()

    // Optional inverse relationships (all optional for CloudKit compatibility).
    @Relationship(deleteRule: .cascade, inverse: \ToneSetting.gear)
    var settings: [ToneSetting]? = []

    init(
        name: String = "",
        type: GearType = .pedal,
        template: ControlTemplate = .threeKnob,
        brandColorHex: String? = nil,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.templateRaw = template.rawValue
        self.brandColorHex = brandColorHex
        self.notes = notes
        self.dateCreated = Date()
        self.customLabelsJSON = "{}"
    }

    // MARK: - Convenience accessors

    var type: GearType {
        get { GearType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var template: ControlTemplate {
        get { ControlTemplate(rawValue: templateRaw) ?? .threeKnob }
        set { templateRaw = newValue.rawValue }
    }

    /// The control specs for this gear, with any user label overrides applied.
    var controls: [ControlSpec] {
        let overrides = customLabels
        return template.controls.map { spec in
            var s = spec
            if let custom = overrides[spec.id], !custom.isEmpty { s.label = custom }
            return s
        }
    }

    var customLabels: [Int: String] {
        get {
            guard let data = customLabelsJSON.data(using: .utf8),
                  let raw = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
                Int(key).map { ($0, value) }
            })
        }
        set {
            let raw = Dictionary(uniqueKeysWithValues: newValue.map { (String($0.key), $0.value) })
            if let data = try? JSONEncoder().encode(raw),
               let json = String(data: data, encoding: .utf8) {
                customLabelsJSON = json
            }
        }
    }

    var sortedSettings: [ToneSetting] {
        (settings ?? []).sorted { $0.dateCreated > $1.dateCreated }
    }
}
