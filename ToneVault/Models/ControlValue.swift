import Foundation
import SwiftData

/// A single control's stored value inside a saved ToneSetting.
///
/// `value` semantics depend on the control kind (resolved from the parent gear's template):
///   - knob:     0.0 ... 10.0
///   - slider:   0.0 ... 100.0
///   - toggle:   0.0 (off) or 1.0 (on)
///   - selector: 0.0 ... (positions - 1), integer-valued
@Model
final class ControlValue {
    var id: UUID = UUID()
    /// The control's stable id within the template (matches ControlSpec.id).
    var controlIndex: Int = 0
    /// Snapshot of the label at save time (so exports read well even if gear labels change).
    var label: String = ""
    /// Snapshot of the kind's raw value, so the value can be formatted without the gear.
    var kindRaw: String = ControlKind.knob.rawValue
    var value: Double = 0.0

    @Relationship(inverse: \ToneSetting.controlValues)
    var setting: ToneSetting?

    init(controlIndex: Int, label: String, kind: ControlKind, value: Double) {
        self.id = UUID()
        self.controlIndex = controlIndex
        self.label = label
        self.kindRaw = kind.rawValue
        self.value = value
    }

    var kind: ControlKind {
        ControlKind(rawValue: kindRaw) ?? .knob
    }
}
