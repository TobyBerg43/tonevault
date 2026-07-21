import SwiftUI
import SwiftData

struct SongListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Song.title) private var songs: [Song]
    @State private var showingNew = false
    @State private var searchText = ""

    private var filteredSongs: [Song] {
        songs.filter { SearchFilter.songMatches($0, query: searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if songs.isEmpty {
                    EmptyStateView(
                        systemImage: "music.note.list",
                        title: "No songs yet",
                        message: "Group the tones you use for a song, so you can recall the whole rig at a glance."
                    ) {
                        Button { showingNew = true } label: { Label("Add song", systemImage: "plus") }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            NavigationLink {
                                SongDetailView(song: song)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title.isEmpty ? "Untitled" : song.title)
                                        .font(.body).fontWeight(.medium)
                                    Text(subtitle(for: song))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .searchable(text: $searchText, prompt: "Search songs")
                    .overlay {
                        if filteredSongs.isEmpty && !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                }
            }
            .navigationTitle("Songs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                SongEditorView(song: nil)
            }
        }
    }

    private func subtitle(for song: Song) -> String {
        let count = (song.toneSettings ?? []).count
        let artist = song.artist ?? ""
        let tones = "\(count) tone\(count == 1 ? "" : "s")"
        return artist.isEmpty ? tones : "\(artist) · \(tones)"
    }

    private func delete(_ offsets: IndexSet) {
        let visible = filteredSongs
        for i in offsets { context.delete(visible[i]) }
    }
}

/// Create/rename a song.
struct SongEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let song: Song?

    @State private var title = ""
    @State private var artist = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Artist (optional)", text: $artist)
                TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(2...5)
            }
            .navigationTitle(song == nil ? "New Song" : "Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let song {
                    title = song.title; artist = song.artist ?? ""; notes = song.notes
                }
            }
        }
    }

    private func save() {
        let target = song ?? {
            let s = Song(); context.insert(s); return s
        }()
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.artist = artist.isEmpty ? nil : artist
        target.notes = notes
        Haptics.success()
        dismiss()
    }
}
