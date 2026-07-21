import Foundation

/// Tiny, testable search matching used by the Library and Songs lists.
/// Case- and diacritic-insensitive substring match over any of the candidates.
enum SearchFilter {

    static func matches(query: String, candidates: [String?]) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        return candidates.contains { candidate in
            guard let candidate, !candidate.isEmpty else { return false }
            return candidate.range(of: trimmed,
                                   options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    static func gearMatches(_ gear: Gear, query: String) -> Bool {
        matches(query: query, candidates: [gear.name, gear.type.displayName, gear.template.shortName])
    }

    static func toneMatches(_ setting: ToneSetting, query: String) -> Bool {
        matches(query: query, candidates: [setting.name, setting.gear?.name, setting.notes])
    }

    static func songMatches(_ song: Song, query: String) -> Bool {
        matches(query: query, candidates: [song.title, song.artist])
    }
}
