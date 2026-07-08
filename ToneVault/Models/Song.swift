import Foundation
import SwiftData

/// A song groups multiple ToneSettings — the full rig used to play it.
@Model
final class Song {
    var id: UUID = UUID()
    var title: String = ""
    var artist: String?
    var notes: String = ""
    var dateCreated: Date = Date()

    /// The tone settings used in this song (across multiple pedals/amps).
    @Relationship
    var toneSettings: [ToneSetting]? = []

    @Relationship(inverse: \Setlist.songs)
    var setlists: [Setlist]? = []

    init(title: String = "", artist: String? = nil, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.notes = notes
        self.dateCreated = Date()
    }

    var sortedSettings: [ToneSetting] {
        (toneSettings ?? []).sorted {
            ($0.gear?.name ?? "") < ($1.gear?.name ?? "")
        }
    }
}
