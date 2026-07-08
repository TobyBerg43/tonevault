import UIKit

/// Renders human-readable "rig cheat-sheet" PDFs for a song or a whole setlist.
/// Printable for a gig. (Pro feature; the free tier still gets full JSON backup/export.)
enum PDFExportService {

    private static let pageSize = CGSize(width: 612, height: 792) // US Letter @72dpi
    private static let margin: CGFloat = 48

    static func exportSong(_ song: Song, style: KnobDisplayStyle) -> URL? {
        render(title: song.title.isEmpty ? "Song" : song.title,
               fileStem: "ToneVault-\(safe(song.title))",
               sections: [songSection(song, style: style)])
    }

    static func exportSetlist(_ setlist: Setlist, style: KnobDisplayStyle) -> URL? {
        let sections = setlist.orderedSongs.enumerated().map { index, song in
            songSection(song, style: style, number: index + 1)
        }
        return render(title: setlist.name.isEmpty ? "Setlist" : setlist.name,
                      fileStem: "ToneVault-\(safe(setlist.name))",
                      sections: sections)
    }

    // MARK: - Model → printable section

    private struct RigLine { let gear: String; let tone: String; let controls: String }
    private struct RigSection { let heading: String; let lines: [RigLine] }

    private static func songSection(_ song: Song, style: KnobDisplayStyle, number: Int? = nil) -> RigSection {
        let prefix = number.map { "\($0). " } ?? ""
        let artist = (song.artist?.isEmpty == false) ? " — \(song.artist!)" : ""
        let lines = song.sortedSettings.map { setting in
            let controls = setting.sortedControlValues.map { cv -> String in
                let spec = setting.gear?.controls.first { $0.id == cv.controlIndex }
                let v = ControlValueFormatter.string(for: cv.value, kind: cv.kind, style: style,
                                                     selectorPositions: spec?.selectorPositions ?? 3)
                return "\(cv.label): \(v)"
            }.joined(separator: "   ")
            return RigLine(gear: setting.gear?.name ?? "Gear", tone: setting.name, controls: controls)
        }
        return RigSection(heading: "\(prefix)\(song.title)\(artist)", lines: lines)
    }

    // MARK: - Rendering

    private static func render(title: String, fileStem: String, sections: [RigSection]) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileStem).pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                var y: CGFloat = margin
                ctx.beginPage()
                y = drawHeader(title: title, at: y)

                for section in sections {
                    if y > pageSize.height - 140 { ctx.beginPage(); y = margin }
                    y = drawSectionHeading(section.heading, at: y)
                    if section.lines.isEmpty {
                        y = drawText("(no tones saved for this song)", font: italic(11),
                                     color: .gray, at: y, x: margin + 8)
                        y += 6
                    }
                    for line in section.lines {
                        if y > pageSize.height - 90 { ctx.beginPage(); y = margin }
                        y = drawText("\(line.gear)  ·  \(line.tone)", font: bold(13), at: y, x: margin + 8)
                        y = drawText(line.controls, font: regular(12), color: .darkGray,
                                     at: y, x: margin + 16, width: pageSize.width - 2 * margin - 16)
                        y += 10
                    }
                    y += 8
                }

                drawFooter()
            }
            return url
        } catch {
            return nil
        }
    }

    private static func drawHeader(title: String, at y: CGFloat) -> CGFloat {
        var y = y
        let brand = "ToneVault"
        brand.draw(at: CGPoint(x: margin, y: y), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor(red: 0.88, green: 0.33, blue: 0.22, alpha: 1)
        ])
        y += 20
        y = drawText(title, font: bold(24), at: y, x: margin)
        y += 6
        let df = DateFormatter(); df.dateStyle = .medium
        y = drawText("Rig cheat-sheet · \(df.string(from: Date()))", font: regular(11), color: .gray, at: y, x: margin)
        y += 14
        // divider
        UIColor.lightGray.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        path.lineWidth = 0.5
        path.stroke()
        return y + 16
    }

    private static func drawSectionHeading(_ text: String, at y: CGFloat) -> CGFloat {
        drawText(text, font: bold(16), color: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1), at: y, x: margin) + 6
    }

    @discardableResult
    private static func drawText(_ text: String, font: UIFont, color: UIColor = .black,
                                 at y: CGFloat, x: CGFloat, width: CGFloat? = nil) -> CGFloat {
        let maxWidth = width ?? (pageSize.width - x - margin)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil)
        (text as NSString).draw(with: CGRect(x: x, y: y, width: maxWidth, height: rect.height),
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: attrs, context: nil)
        return y + rect.height + 2
    }

    private static func drawFooter() {
        let text = "Generated by ToneVault · Not affiliated with any manufacturer"
        (text as NSString).draw(at: CGPoint(x: margin, y: pageSize.height - 30),
                                withAttributes: [.font: regular(9), .foregroundColor: UIColor.gray])
    }

    private static func regular(_ s: CGFloat) -> UIFont { .systemFont(ofSize: s) }
    private static func bold(_ s: CGFloat) -> UIFont { .boldSystemFont(ofSize: s) }
    private static func italic(_ s: CGFloat) -> UIFont { .italicSystemFont(ofSize: s) }

    private static func safe(_ s: String) -> String {
        let stem = s.isEmpty ? "export" : s
        return stem.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
    }
}
