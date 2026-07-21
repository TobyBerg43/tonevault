import XCTest
import SwiftData
@testable import ToneVault

final class ToneVaultTests: XCTestCase {

    // MARK: - Helpers

    /// Kept alive for the duration of each test: on newer OS runtimes a
    /// ModelContext does NOT retain its ModelContainer, so a function-local
    /// container would be deallocated and the first insert would crash.
    private var container: ModelContainer?

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Gear.self, ToneSetting.self, ControlValue.self, Song.self, Setlist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        self.container = container
        return container.mainContext
    }

    // MARK: - Formatting

    func testKnobClockFormatting() {
        XCTAssertEqual(ControlValueFormatter.clock(for: 0), "7 o'clock")
        XCTAssertEqual(ControlValueFormatter.clock(for: 10), "5 o'clock")
        // Midpoint should land at 12 o'clock (index 5 of the 11-stop sweep).
        XCTAssertEqual(ControlValueFormatter.clock(for: 5), "12 o'clock")
    }

    func testControlValueFormatting() {
        XCTAssertEqual(ControlValueFormatter.string(for: 7.5, kind: .knob, style: .numeric), "7.5")
        XCTAssertEqual(ControlValueFormatter.string(for: 6.0, kind: .knob, style: .numeric), "6")
        XCTAssertEqual(ControlValueFormatter.string(for: 68, kind: .slider, style: .numeric), "68%")
        XCTAssertEqual(ControlValueFormatter.string(for: 1, kind: .toggle, style: .numeric), "On")
        XCTAssertEqual(ControlValueFormatter.string(for: 0, kind: .toggle, style: .numeric), "Off")
        XCTAssertEqual(ControlValueFormatter.string(for: 2, kind: .selector, style: .numeric, selectorPositions: 5), "Pos 3 of 5")
    }

    // MARK: - Control value seeding

    @MainActor
    func testSyncControlValuesSeedsDefaults() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "G", type: .pedal, template: .threeKnob)
        ctx.insert(gear)
        let tone = ToneSetting(name: "T", gear: gear)
        ctx.insert(tone)
        tone.syncControlValues(in: ctx)

        XCTAssertEqual(tone.controlValues?.count, 3)
        XCTAssertEqual(Set(tone.sortedControlValues.map(\.label)), ["Drive", "Tone", "Level"])
        XCTAssertTrue(tone.sortedControlValues.allSatisfy { $0.value == 5.0 })
    }

    @MainActor
    func testTemplateChangeKeepsAndSeeds() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "G", type: .pedal, template: .threeKnob)
        ctx.insert(gear)
        let tone = ToneSetting(name: "T", gear: gear)
        ctx.insert(tone)
        tone.syncControlValues(in: ctx)
        tone.sortedControlValues[0].value = 8.0 // change Drive

        // Grow the template to 6 knobs.
        gear.template = .sixKnob
        tone.syncControlValues(in: ctx)
        XCTAssertEqual(tone.controlValues?.count, 6)
        XCTAssertEqual(tone.sortedControlValues[0].value, 8.0, "existing control value preserved")
        XCTAssertEqual(tone.sortedControlValues[5].value, 5.0, "new control seeded to default")

        // Shrink the template — orphans removed.
        gear.template = .threeKnob
        tone.syncControlValues(in: ctx)
        XCTAssertEqual(tone.controlValues?.count, 3)
    }

    @MainActor
    func testCloneIsIndependent() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "G", template: .threeKnob)
        ctx.insert(gear)
        let tone = ToneSetting(name: "Base", gear: gear)
        ctx.insert(tone)
        tone.syncControlValues(in: ctx)
        tone.sortedControlValues[0].value = 4.0

        let clone = tone.clone(in: ctx)
        XCTAssertEqual(clone.name, "Base copy")
        XCTAssertEqual(clone.sortedControlValues[0].value, 4.0)

        clone.sortedControlValues[0].value = 9.0
        XCTAssertEqual(tone.sortedControlValues[0].value, 4.0, "editing clone must not affect original")
    }

    // MARK: - Setlist ordering

    @MainActor
    func testSetlistOrdering() throws {
        let ctx = try makeContext()
        let s1 = Song(title: "One"); let s2 = Song(title: "Two"); let s3 = Song(title: "Three")
        [s1, s2, s3].forEach { ctx.insert($0) }
        let setlist = Setlist(name: "Gig")
        ctx.insert(setlist)
        setlist.addSong(s1); setlist.addSong(s2); setlist.addSong(s3)
        XCTAssertEqual(setlist.orderedSongs.map(\.title), ["One", "Two", "Three"])

        setlist.moveSongs(fromOffsets: IndexSet(integer: 2), toOffset: 0)
        XCTAssertEqual(setlist.orderedSongs.first?.title, "Three")

        setlist.removeSong(s1)
        XCTAssertFalse(setlist.orderedSongs.contains { $0.title == "One" })
    }

    // MARK: - Backup round trip

    @MainActor
    func testBackupRoundTrip() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "Round Trip", template: .ampHead, brandColorHex: "#3A72E0")
        ctx.insert(gear)
        let tone = ToneSetting(name: "Clean", gear: gear)
        ctx.insert(tone)
        tone.syncControlValues(in: ctx)
        tone.sortedControlValues[0].value = 4.0
        tone.isFavorite = true
        let song = Song(title: "Song A", artist: "Artist")
        ctx.insert(song)
        song.toneSettings = [tone]
        let setlist = Setlist(name: "Set A")
        ctx.insert(setlist)
        setlist.addSong(song)
        try ctx.save()

        let url = try BackupService.exportBackup(context: ctx)
        let counts = try BackupService.importBackup(from: url, context: ctx)

        XCTAssertEqual(counts.gear, 1)
        XCTAssertEqual(counts.settings, 1)
        XCTAssertEqual(counts.songs, 1)
        XCTAssertEqual(counts.setlists, 1)

        let gears = try ctx.fetch(FetchDescriptor<Gear>())
        XCTAssertEqual(gears.count, 1)
        let restoredTone = try ctx.fetch(FetchDescriptor<ToneSetting>()).first
        XCTAssertEqual(restoredTone?.name, "Clean")
        XCTAssertEqual(restoredTone?.isFavorite, true)
        XCTAssertEqual(restoredTone?.sortedControlValues.first?.value, 4.0)
        XCTAssertEqual(restoredTone?.gear?.name, "Round Trip")

        let restoredSetlist = try ctx.fetch(FetchDescriptor<Setlist>()).first
        XCTAssertEqual(restoredSetlist?.orderedSongs.first?.title, "Song A")
    }

    // MARK: - Sample content (onboarding)

    @MainActor
    func testSampleContentInstallsOnceOnly() throws {
        let ctx = try makeContext()
        let pedal = SampleContent.install(in: ctx)
        XCTAssertNotNil(pedal)
        XCTAssertEqual(pedal?.name, SampleContent.gearName)
        XCTAssertEqual(pedal?.template, .threeKnob)

        let tones = try ctx.fetch(FetchDescriptor<ToneSetting>())
        XCTAssertEqual(tones.count, 2)
        // Every tone has a full set of seeded, non-default-looking values.
        for tone in tones {
            XCTAssertEqual(tone.controlValues?.count, 3)
        }
        let crunch = tones.first { $0.name == "Crunch rhythm" }
        XCTAssertEqual(crunch?.sortedControlValues.map(\.value), [6.5, 4.0, 5.5])

        // Second install is a no-op.
        XCTAssertNil(SampleContent.install(in: ctx))
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Gear>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ToneSetting>()).count, 2)
    }

    // MARK: - Search

    @MainActor
    func testSearchFilterMatching() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "Blües Drivér", type: .pedal, template: .threeKnob)
        ctx.insert(gear)
        let tone = ToneSetting(name: "Solo boost", gear: gear, notes: "for the bridge")
        ctx.insert(tone)
        let song = Song(title: "Midnight Run", artist: "The Locals")
        ctx.insert(song)

        // Case- and diacritic-insensitive, substring, empty query matches all.
        XCTAssertTrue(SearchFilter.gearMatches(gear, query: "blues dri"))
        XCTAssertTrue(SearchFilter.gearMatches(gear, query: "  "))
        XCTAssertFalse(SearchFilter.gearMatches(gear, query: "fuzz"))
        // Tones match on their own name, gear name, or notes.
        XCTAssertTrue(SearchFilter.toneMatches(tone, query: "SOLO"))
        XCTAssertTrue(SearchFilter.toneMatches(tone, query: "bluès"))
        XCTAssertTrue(SearchFilter.toneMatches(tone, query: "bridge"))
        XCTAssertFalse(SearchFilter.toneMatches(tone, query: "chorus"))
        // Songs match title or artist.
        XCTAssertTrue(SearchFilter.songMatches(song, query: "midnight"))
        XCTAssertTrue(SearchFilter.songMatches(song, query: "locals"))
        XCTAssertFalse(SearchFilter.songMatches(song, query: "sunrise"))
    }

    // MARK: - Share card

    @MainActor
    func testToneShareCardRenders() throws {
        let ctx = try makeContext()
        let gear = Gear(name: "Share Pedal", type: .pedal, template: .ampHead)
        ctx.insert(gear)
        let tone = ToneSetting(name: "Big lead", gear: gear)
        ctx.insert(tone)
        tone.syncControlValues(in: ctx)

        let image = ToneCardRenderer.render(setting: tone, style: .clock)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 300)
        XCTAssertGreaterThan(image?.size.height ?? 0, 100)
    }

    // MARK: - Free-tier gating

    @MainActor
    func testFreeTierGating() {
        let mgr = EntitlementManager()
        // Fresh manager is not Pro (no purchase in test environment).
        XCTAssertFalse(mgr.isPro)
        XCTAssertTrue(mgr.canAddGear(currentCount: 4))
        XCTAssertFalse(mgr.canAddGear(currentCount: EntitlementManager.freeGearLimit))
        XCTAssertTrue(mgr.canAddSetting(currentCount: 9))
        XCTAssertFalse(mgr.canAddSetting(currentCount: EntitlementManager.freeSettingLimit))

        #if DEBUG
        mgr.debugSimulatePro = true
        XCTAssertTrue(mgr.isPro)
        XCTAssertTrue(mgr.canAddGear(currentCount: 999))
        XCTAssertTrue(mgr.canAddSetting(currentCount: 999))
        #endif
    }
}
