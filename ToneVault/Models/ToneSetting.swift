import Foundation
import SwiftData

/// A saved snapshot of a gear's control positions — e.g. "Verse tone" for a Boss DS-1.
@Model
final class ToneSetting {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var photoFilename: String?
    var audioFilename: String?
    var isFavorite: Bool = false
    var dateCreated: Date = Date()
    var dateModified: Date = Date()

    @Relationship
    var gear: Gear?

    @Relationship(deleteRule: .cascade)
    var controlValues: [ControlValue]? = []

    /// A ToneSetting can be attached to many songs (a tone reused across songs).
    @Relationship(inverse: \Song.toneSettings)
    var songs: [Song]? = []

    init(name: String = "", gear: Gear? = nil, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.gear = gear
        self.notes = notes
        self.dateCreated = Date()
        self.dateModified = Date()
    }

    var sortedControlValues: [ControlValue] {
        (controlValues ?? []).sorted { $0.controlIndex < $1.controlIndex }
    }

    /// Ensures a ControlValue exists for every control on the gear's template,
    /// seeding defaults for any missing ones. Safe to call repeatedly.
    func syncControlValues(in context: ModelContext) {
        guard let gear else { return }
        var existing = Dictionary(uniqueKeysWithValues: (controlValues ?? []).map { ($0.controlIndex, $0) })
        var result: [ControlValue] = []
        for spec in gear.controls {
            if let cv = existing[spec.id] {
                cv.label = spec.label
                cv.kindRaw = spec.kind.rawValue
                result.append(cv)
                existing[spec.id] = nil
            } else {
                let cv = ControlValue(
                    controlIndex: spec.id,
                    label: spec.label,
                    kind: spec.kind,
                    value: ControlTemplate.defaultValue(for: spec)
                )
                cv.setting = self
                context.insert(cv)
                result.append(cv)
            }
        }
        // Remove any orphaned values (template changed to fewer controls).
        for orphan in existing.values {
            context.delete(orphan)
        }
        controlValues = result
    }

    /// One-tap clone: duplicates the setting and its control values (same gear).
    @discardableResult
    func clone(in context: ModelContext) -> ToneSetting {
        let copy = ToneSetting(name: "\(name) copy", gear: gear, notes: notes)
        copy.isFavorite = false
        context.insert(copy)
        var values: [ControlValue] = []
        for cv in sortedControlValues {
            let newCV = ControlValue(controlIndex: cv.controlIndex, label: cv.label, kind: cv.kind, value: cv.value)
            newCV.setting = copy
            context.insert(newCV)
            values.append(newCV)
        }
        copy.controlValues = values
        return copy
    }
}
