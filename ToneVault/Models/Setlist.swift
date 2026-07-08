import Foundation
import SwiftData

/// An ordered list of songs for a gig. Pull it up on stage to see every rig setting per song.
@Model
final class Setlist {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var dateCreated: Date = Date()

    @Relationship
    var songs: [Song]? = []

    /// Explicit ordering of song ids (SwiftData relationships are unordered).
    /// Stored as JSON of UUID strings for CloudKit-friendliness.
    var orderJSON: String = "[]"

    init(name: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.dateCreated = Date()
        self.orderJSON = "[]"
    }

    var order: [UUID] {
        get {
            guard let data = orderJSON.data(using: .utf8),
                  let raw = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return raw.compactMap(UUID.init(uuidString:))
        }
        set {
            let raw = newValue.map(\.uuidString)
            if let data = try? JSONEncoder().encode(raw),
               let json = String(data: data, encoding: .utf8) {
                orderJSON = json
            }
        }
    }

    /// Songs in gig order. Any song not yet in `order` is appended by creation date.
    var orderedSongs: [Song] {
        let all = songs ?? []
        let index = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        var result: [Song] = []
        for id in order {
            if let song = index[id] { result.append(song) }
        }
        let remaining = all
            .filter { song in !order.contains(song.id) }
            .sorted { $0.dateCreated < $1.dateCreated }
        result.append(contentsOf: remaining)
        return result
    }

    func addSong(_ song: Song) {
        var current = songs ?? []
        guard !current.contains(where: { $0.id == song.id }) else { return }
        current.append(song)
        songs = current
        var o = order
        o.append(song.id)
        order = o
    }

    func removeSong(_ song: Song) {
        songs = (songs ?? []).filter { $0.id != song.id }
        order = order.filter { $0 != song.id }
    }

    func moveSongs(fromOffsets: IndexSet, toOffset: Int) {
        var current = orderedSongs
        let moving = fromOffsets.sorted().map { current[$0] }
        for idx in fromOffsets.sorted(by: >) { current.remove(at: idx) }
        let insertAt = toOffset - fromOffsets.filter { $0 < toOffset }.count
        current.insert(contentsOf: moving, at: min(max(insertAt, 0), current.count))
        order = current.map(\.id)
    }
}
