import SwiftUI
import SwiftData

/// Ordered songs for a gig. Reorder, add/remove, open a big stage-readable rig view,
/// and export the whole setlist to PDF.
struct SetlistDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    @Bindable var setlist: Setlist
    @State private var showingSongPicker = false
    @State private var showingEdit = false
    @State private var showingShare = false
    @State private var showingPaywall = false
    @State private var exportURL: URL?
    @State private var editMode: EditMode = .inactive

    private var style: KnobDisplayStyle { KnobDisplayStyle(rawValue: styleRaw) ?? .numeric }

    var body: some View {
        List {
            Section {
                if setlist.orderedSongs.isEmpty {
                    Text("No songs yet. Tap “Add songs” to build the gig.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(Array(setlist.orderedSongs.enumerated()), id: \.element.id) { index, song in
                    NavigationLink {
                        StageView(songs: setlist.orderedSongs,
                                  title: setlist.name.isEmpty ? "Stage" : setlist.name,
                                  style: style,
                                  startIndex: index)
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title.isEmpty ? "Untitled" : song.title)
                                    .font(.body).fontWeight(.medium)
                                Text("\((song.toneSettings ?? []).count) tones")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onMove { setlist.moveSongs(fromOffsets: $0, toOffset: $1) }
                .onDelete { offsets in
                    let songs = setlist.orderedSongs
                    for i in offsets { setlist.removeSong(songs[i]) }
                }
            } header: {
                Text("Songs (\(setlist.orderedSongs.count)) — tap for stage view")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !setlist.orderedSongs.isEmpty {
                NavigationLink {
                    StageView(songs: setlist.orderedSongs,
                              title: setlist.name.isEmpty ? "Stage" : setlist.name,
                              style: style)
                } label: {
                    Label("Start stage mode", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .navigationTitle(setlist.name.isEmpty ? "Setlist" : setlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingSongPicker = true } label: { Label("Add songs", systemImage: "plus") }
                    Button { withAnimation { editMode = editMode == .active ? .inactive : .active } } label: {
                        Label(editMode == .active ? "Done reordering" : "Reorder", systemImage: "arrow.up.arrow.down")
                    }
                    Button { showingEdit = true } label: { Label("Rename", systemImage: "pencil") }
                    Button { exportPDF() } label: { Label("Export setlist PDF", systemImage: "doc.richtext") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingSongPicker) {
            SongPickerView { songs in
                for s in songs { setlist.addSong(s) }
            }
        }
        .sheet(isPresented: $showingEdit) { SetlistEditorView(setlist: setlist) }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
    }

    private func exportPDF() {
        guard entitlements.canExportPDF else { showingPaywall = true; return }
        if let url = PDFExportService.exportSetlist(setlist, style: style) {
            exportURL = url
            showingShare = true
        }
    }
}

/// Multi-select song picker for building a setlist.
struct SongPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Song.title) private var songs: [Song]
    @State private var selected: Set<UUID> = []
    var onDone: ([Song]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(songs) { song in
                    Button {
                        if selected.contains(song.id) { selected.remove(song.id) } else { selected.insert(song.id) }
                    } label: {
                        HStack {
                            Text(song.title.isEmpty ? "Untitled" : song.title)
                            Spacer()
                            if selected.contains(song.id) {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if songs.isEmpty {
                    ContentUnavailableView("No songs yet", systemImage: "music.note",
                        description: Text("Create songs first, then add them to a setlist."))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onDone(songs.filter { selected.contains($0.id) })
                        dismiss()
                    }.disabled(selected.isEmpty)
                }
            }
        }
    }
}
