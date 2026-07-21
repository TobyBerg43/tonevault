import Foundation
import SwiftData

#if DEBUG
/// In-memory container with a little sample data for SwiftUI previews only.
enum PreviewData {
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema([Gear.self, ToneSetting.self, ControlValue.self, Song.self, Setlist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext

        let ds1 = Gear(name: "Orange Drive Box", type: .pedal, template: .threeKnob, brandColorHex: "#E08A2E")
        ctx.insert(ds1)
        let verse = ToneSetting(name: "Verse tone", gear: ds1)
        ctx.insert(verse)
        verse.syncControlValues(in: ctx)
        verse.controlValues?.first?.value = 3.5

        let amp = Gear(name: "Studio Combo", type: .amp, template: .ampHead, brandColorHex: "#3A72E0")
        ctx.insert(amp)
        let clean = ToneSetting(name: "Clean rhythm", gear: amp)
        ctx.insert(clean)
        clean.syncControlValues(in: ctx)

        let song = Song(title: "Midnight Run", artist: "The Locals")
        ctx.insert(song)
        song.toneSettings = [verse, clean]

        let setlist = Setlist(name: "Friday @ The Basement")
        ctx.insert(setlist)
        setlist.addSong(song)

        return container
    }()
}
#endif
