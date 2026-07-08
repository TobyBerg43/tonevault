import Foundation
import UIKit

/// Manages local JPEG photo and audio-clip files. SwiftData stores only filenames;
/// the bytes live as files in Application Support (never as blobs in the store).
enum FileStorage {

    private static let photosDir = "Photos"
    private static let audioDir = "Audio"

    private static func baseURL() -> URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
    }

    private static func directory(_ name: String) -> URL {
        let url = baseURL().appendingPathComponent(name, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // MARK: - Photos

    /// Writes a JPEG and returns the generated filename (to store on the model).
    @discardableResult
    static func savePhoto(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let filename = "photo_\(UUID().uuidString).jpg"
        let url = directory(photosDir).appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func photoURL(_ filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else { return nil }
        return directory(photosDir).appendingPathComponent(filename)
    }

    static func loadPhoto(_ filename: String?) -> UIImage? {
        guard let url = photoURL(filename), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Audio

    /// Returns a fresh URL to record into; caller stores the filename on the model.
    static func newAudioURL() -> (filename: String, url: URL) {
        let filename = "audio_\(UUID().uuidString).m4a"
        return (filename, directory(audioDir).appendingPathComponent(filename))
    }

    static func audioURL(_ filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else { return nil }
        return directory(audioDir).appendingPathComponent(filename)
    }

    // MARK: - Deletion

    static func deletePhoto(_ filename: String?) {
        if let url = photoURL(filename) { try? FileManager.default.removeItem(at: url) }
    }

    static func deleteAudio(_ filename: String?) {
        if let url = audioURL(filename) { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: - Backup helpers

    /// All attachment files, for inclusion in a full backup archive.
    static func allAttachmentURLs() -> [URL] {
        let fm = FileManager.default
        var urls: [URL] = []
        for dir in [directory(photosDir), directory(audioDir)] {
            if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                urls.append(contentsOf: items)
            }
        }
        return urls
    }

    static func photosDirectoryURL() -> URL { directory(photosDir) }
    static func audioDirectoryURL() -> URL { directory(audioDir) }
}
