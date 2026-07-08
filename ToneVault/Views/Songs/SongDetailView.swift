import SwiftUI
import SwiftData

/// The full rig for a song: every tone used, grouped by gear. Add/remove tones.
struct SongDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    @Bindable var song: Song
    @State private var showingPicker = false
    @State private var showingEdit = false
    @State private var showingShare = false
    @State private var exportURL: URL?
    @State private var showingPaywall = false

    private var style: KnobDisplayStyle { KnobDisplayStyle(rawValue: styleRaw) ?? .numeric }

    var body: some View {
        List {
            if let artist = song.artist, !artist.isEmpty {
                Section { LabeledContent("Artist", value: artist) }
            }
            if !song.notes.isEmpty {
                Section("Notes") { Text(song.notes).foregroundStyle(.secondary) }
            }

            Section("Rig for this song (\(song.sortedSettings.count))") {
                if song.sortedSettings.isEmpty {
                    Text("No tones added yet. Tap “Add tone” to build this song’s rig.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(song.sortedSettings) { setting in
                    NavigationLink {
                        ToneSettingDetailView(setting: setting)
                    } label: {
                        RigSettingRow(setting: setting, style: style)
                    }
                }
                .onDelete(perform: removeTones)
            }
        }
        .navigationTitle(song.title.isEmpty ? "Song" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingPicker = true } label: { Label("Add tone", systemImage: "plus") }
                    Button { showingEdit = true } label: { Label("Edit song", systemImage: "pencil") }
                    Button { exportPDF() } label: { Label("Export rig PDF", systemImage: "doc.richtext") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingPicker) {
            ToneSettingPickerView { selected in
                addTones(selected)
            }
        }
        .sheet(isPresented: $showingEdit) { SongEditorView(song: song) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
    }

    private func addTones(_ settings: [ToneSetting]) {
        var current = song.toneSettings ?? []
        for s in settings where !current.contains(where: { $0.id == s.id }) {
            current.append(s)
        }
        song.toneSettings = current
        Haptics.selection()
    }

    private func removeTones(_ offsets: IndexSet) {
        let items = song.sortedSettings
        var current = song.toneSettings ?? []
        for i in offsets {
            let target = items[i]
            current.removeAll { $0.id == target.id }
        }
        song.toneSettings = current
    }

    private func exportPDF() {
        guard entitlements.canExportPDF else { showingPaywall = true; return }
        if let url = PDFExportService.exportSong(song, style: style) {
            exportURL = url
            showingShare = true
        }
    }
}

struct RigSettingRow: View {
    let setting: ToneSetting
    let style: KnobDisplayStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(setting.gear?.name ?? "No gear").font(.body).fontWeight(.semibold)
                Spacer()
                Text(setting.name).font(.caption).foregroundStyle(.secondary)
            }
            Text(summary)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var summary: String {
        setting.sortedControlValues.map { cv in
            let spec = setting.gear?.controls.first { $0.id == cv.controlIndex }
            let v = ControlValueFormatter.string(for: cv.value, kind: cv.kind, style: style,
                                                 selectorPositions: spec?.selectorPositions ?? 3)
            return "\(cv.label) \(v)"
        }.joined(separator: "  ·  ")
    }
}

/// Multi-select picker over all saved tones (grouped by gear).
struct ToneSettingPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Gear.name) private var gear: [Gear]
    @State private var selected: Set<UUID> = []
    var onDone: ([ToneSetting]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(gear) { g in
                    if !g.sortedSettings.isEmpty {
                        Section(g.name) {
                            ForEach(g.sortedSettings) { s in
                                Button {
                                    toggle(s.id)
                                } label: {
                                    HStack {
                                        Text(s.name.isEmpty ? "Untitled tone" : s.name)
                                        Spacer()
                                        if selected.contains(s.id) {
                                            Image(systemName: "checkmark").foregroundStyle(.tint)
                                        }
                                    }
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Tones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let all = gear.flatMap { $0.sortedSettings }
                        onDone(all.filter { selected.contains($0.id) })
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }
}
