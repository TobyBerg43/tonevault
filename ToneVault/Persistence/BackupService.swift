import Foundation
import SwiftData

/// Whole-database export/import to a single portable `.tonevault` file (JSON).
///
/// The backup embeds photo/audio attachments as base64 so it is genuinely one
/// self-contained file you can email to yourself or drop in iCloud Drive and
/// restore on a new phone. (Live app storage still keeps attachments as files;
/// only the backup inlines them — see DECISIONS.md.)
///
/// Restore REPLACES the current library with the backup's contents.
enum BackupService {

    static let fileExtension = "tonevault"
    static let currentVersion = 1

    struct ImportCounts { let gear, settings, songs, setlists: Int }

    // MARK: - Export

    static func exportBackup(context: ModelContext) throws -> URL {
        let gear = try context.fetch(FetchDescriptor<Gear>())
        let settings = try context.fetch(FetchDescriptor<ToneSetting>())
        let songs = try context.fetch(FetchDescriptor<Song>())
        let setlists = try context.fetch(FetchDescriptor<Setlist>())

        var attachments: [AttachmentDTO] = []
        var seen = Set<String>()
        func addAttachment(_ filename: String?, isPhoto: Bool) {
            guard let filename, !filename.isEmpty, !seen.contains(filename) else { return }
            let url = isPhoto ? FileStorage.photoURL(filename) : FileStorage.audioURL(filename)
            if let url, let data = try? Data(contentsOf: url) {
                attachments.append(AttachmentDTO(filename: filename,
                                                 kind: isPhoto ? .photo : .audio,
                                                 base64: data.base64EncodedString()))
                seen.insert(filename)
            }
        }

        for g in gear { addAttachment(g.photoFilename, isPhoto: true) }
        for s in settings {
            addAttachment(s.photoFilename, isPhoto: true)
            addAttachment(s.audioFilename, isPhoto: false)
        }

        let file = BackupFile(
            version: currentVersion,
            exportedAt: Date(),
            gear: gear.map(GearDTO.init),
            settings: settings.map(ToneSettingDTO.init),
            songs: songs.map(SongDTO.init),
            setlists: setlists.map(SetlistDTO.init),
            attachments: attachments
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(file)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let name = "ToneVault-Backup-\(formatter.string(from: Date())).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Import (replace)

    @discardableResult
    static func importBackup(from url: URL, context: ModelContext) throws -> ImportCounts {
        let needsSecurityScope = url.startAccessingSecurityScopedResource()
        defer { if needsSecurityScope { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(BackupFile.self, from: data)

        // 1. Wipe existing library (attachments included).
        try wipeAll(context: context)

        // 2. Restore attachment files first.
        for att in file.attachments {
            guard let bytes = Data(base64Encoded: att.base64) else { continue }
            let dir = att.kind == .photo ? FileStorage.photosDirectoryURL() : FileStorage.audioDirectoryURL()
            let dest = dir.appendingPathComponent(att.filename)
            try? bytes.write(to: dest, options: .atomic)
        }

        // 3. Rebuild objects, wiring relationships by id.
        var gearByID: [UUID: Gear] = [:]
        for dto in file.gear {
            let g = dto.makeModel()
            context.insert(g)
            gearByID[g.id] = g
        }

        var settingByID: [UUID: ToneSetting] = [:]
        for dto in file.settings {
            let s = dto.makeModel(gearByID: gearByID, context: context)
            context.insert(s)
            settingByID[s.id] = s
        }

        for dto in file.songs {
            let song = dto.makeModel(settingByID: settingByID)
            context.insert(song)
        }

        // Songs must exist before setlists reference them.
        let songByID: [UUID: Song] = try Dictionary(
            uniqueKeysWithValues: context.fetch(FetchDescriptor<Song>()).map { ($0.id, $0) }
        )
        for dto in file.setlists {
            let setlist = dto.makeModel(songByID: songByID)
            context.insert(setlist)
        }

        try context.save()
        return ImportCounts(gear: file.gear.count, settings: file.settings.count,
                            songs: file.songs.count, setlists: file.setlists.count)
    }

    private static func wipeAll(context: ModelContext) throws {
        for s in try context.fetch(FetchDescriptor<ToneSetting>()) {
            FileStorage.deletePhoto(s.photoFilename)
            FileStorage.deleteAudio(s.audioFilename)
        }
        for g in try context.fetch(FetchDescriptor<Gear>()) {
            FileStorage.deletePhoto(g.photoFilename)
        }
        try context.delete(model: Setlist.self)
        try context.delete(model: Song.self)
        try context.delete(model: ControlValue.self)
        try context.delete(model: ToneSetting.self)
        try context.delete(model: Gear.self)
        try context.save()
    }
}

// MARK: - DTOs

private struct BackupFile: Codable {
    var version: Int
    var exportedAt: Date
    var gear: [GearDTO]
    var settings: [ToneSettingDTO]
    var songs: [SongDTO]
    var setlists: [SetlistDTO]
    var attachments: [AttachmentDTO]
}

private struct AttachmentDTO: Codable {
    enum Kind: String, Codable { case photo, audio }
    var filename: String
    var kind: Kind
    var base64: String
}

private struct GearDTO: Codable {
    var id: UUID
    var name: String
    var typeRaw: String
    var templateRaw: String
    var customLabelsJSON: String
    var brandColorHex: String?
    var photoFilename: String?
    var notes: String
    var dateCreated: Date

    init(_ g: Gear) {
        id = g.id; name = g.name; typeRaw = g.typeRaw; templateRaw = g.templateRaw
        customLabelsJSON = g.customLabelsJSON; brandColorHex = g.brandColorHex
        photoFilename = g.photoFilename; notes = g.notes; dateCreated = g.dateCreated
    }

    func makeModel() -> Gear {
        let g = Gear()
        g.id = id; g.name = name; g.typeRaw = typeRaw; g.templateRaw = templateRaw
        g.customLabelsJSON = customLabelsJSON; g.brandColorHex = brandColorHex
        g.photoFilename = photoFilename; g.notes = notes; g.dateCreated = dateCreated
        return g
    }
}

private struct ControlValueDTO: Codable {
    var controlIndex: Int
    var label: String
    var kindRaw: String
    var value: Double

    init(_ cv: ControlValue) {
        controlIndex = cv.controlIndex; label = cv.label; kindRaw = cv.kindRaw; value = cv.value
    }

    func makeModel() -> ControlValue {
        let cv = ControlValue(controlIndex: controlIndex, label: label,
                              kind: ControlKind(rawValue: kindRaw) ?? .knob, value: value)
        return cv
    }
}

private struct ToneSettingDTO: Codable {
    var id: UUID
    var name: String
    var notes: String
    var photoFilename: String?
    var audioFilename: String?
    var isFavorite: Bool
    var dateCreated: Date
    var dateModified: Date
    var gearID: UUID?
    var controlValues: [ControlValueDTO]

    init(_ s: ToneSetting) {
        id = s.id; name = s.name; notes = s.notes
        photoFilename = s.photoFilename; audioFilename = s.audioFilename
        isFavorite = s.isFavorite; dateCreated = s.dateCreated; dateModified = s.dateModified
        gearID = s.gear?.id
        controlValues = s.sortedControlValues.map(ControlValueDTO.init)
    }

    func makeModel(gearByID: [UUID: Gear], context: ModelContext) -> ToneSetting {
        let s = ToneSetting()
        s.id = id; s.name = name; s.notes = notes
        s.photoFilename = photoFilename; s.audioFilename = audioFilename
        s.isFavorite = isFavorite; s.dateCreated = dateCreated; s.dateModified = dateModified
        if let gearID { s.gear = gearByID[gearID] }
        var cvs: [ControlValue] = []
        for dto in controlValues {
            let cv = dto.makeModel()
            cv.setting = s
            context.insert(cv)
            cvs.append(cv)
        }
        s.controlValues = cvs
        return s
    }
}

private struct SongDTO: Codable {
    var id: UUID
    var title: String
    var artist: String?
    var notes: String
    var dateCreated: Date
    var toneSettingIDs: [UUID]

    init(_ song: Song) {
        id = song.id; title = song.title; artist = song.artist
        notes = song.notes; dateCreated = song.dateCreated
        toneSettingIDs = (song.toneSettings ?? []).map(\.id)
    }

    func makeModel(settingByID: [UUID: ToneSetting]) -> Song {
        let song = Song()
        song.id = id; song.title = title; song.artist = artist
        song.notes = notes; song.dateCreated = dateCreated
        song.toneSettings = toneSettingIDs.compactMap { settingByID[$0] }
        return song
    }
}

private struct SetlistDTO: Codable {
    var id: UUID
    var name: String
    var notes: String
    var dateCreated: Date
    var songIDs: [UUID]
    var orderJSON: String

    init(_ setlist: Setlist) {
        id = setlist.id; name = setlist.name; notes = setlist.notes
        dateCreated = setlist.dateCreated
        songIDs = (setlist.songs ?? []).map(\.id)
        orderJSON = setlist.orderJSON
    }

    func makeModel(songByID: [UUID: Song]) -> Setlist {
        let setlist = Setlist()
        setlist.id = id; setlist.name = name; setlist.notes = notes
        setlist.dateCreated = dateCreated
        setlist.songs = songIDs.compactMap { songByID[$0] }
        setlist.orderJSON = orderJSON
        return setlist
    }
}
