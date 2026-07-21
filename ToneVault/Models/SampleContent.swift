import Foundation
import SwiftData

/// Optional example content installed from the welcome screen so a first-time
/// user sees the knob UI working immediately. Entirely generic (no brands),
/// clearly named, and trivially deletable like any user data.
enum SampleContent {

    static let gearName = "Example Drive Pedal"

    /// True if the example gear is already in the library.
    static func isInstalled(in context: ModelContext) -> Bool {
        let name = gearName
        let descriptor = FetchDescriptor<Gear>(predicate: #Predicate { $0.name == name })
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Creates one example pedal with two saved tones. Safe to call once;
    /// does nothing if the example gear already exists.
    @discardableResult
    static func install(in context: ModelContext) -> Gear? {
        guard !isInstalled(in: context) else { return nil }

        let pedal = Gear(
            name: gearName,
            type: .pedal,
            template: .threeKnob,
            brandColorHex: GearColorPreset.orange.rawValue,
            notes: "An example so you can see how ToneVault works. Delete it anytime — swipe left on it in the Library."
        )
        context.insert(pedal)

        let crunch = ToneSetting(name: "Crunch rhythm", gear: pedal,
                                 notes: "Example tone — open it and drag the knobs.")
        context.insert(crunch)
        crunch.syncControlValues(in: context)
        setValues(crunch, [6.5, 4.0, 5.5])

        let lead = ToneSetting(name: "Lead boost", gear: pedal,
                               notes: "Example tone — clone it to make a variant.")
        lead.isFavorite = true
        context.insert(lead)
        lead.syncControlValues(in: context)
        setValues(lead, [8.0, 5.5, 7.0])

        return pedal
    }

    private static func setValues(_ setting: ToneSetting, _ values: [Double]) {
        for (cv, v) in zip(setting.sortedControlValues, values) {
            cv.value = v
        }
    }
}
