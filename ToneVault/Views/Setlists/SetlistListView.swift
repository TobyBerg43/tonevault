import SwiftUI
import SwiftData

struct SetlistListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Setlist.dateCreated, order: .reverse) private var setlists: [Setlist]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            Group {
                if setlists.isEmpty {
                    EmptyStateView(
                        systemImage: "list.number",
                        title: "No setlists yet",
                        message: "Build an ordered list of songs for a gig. On stage, tap a song to see every knob setting — big and readable in a dark venue."
                    ) {
                        Button { showingNew = true } label: { Label("New setlist", systemImage: "plus") }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(setlists) { setlist in
                            NavigationLink {
                                SetlistDetailView(setlist: setlist)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(setlist.name.isEmpty ? "Untitled setlist" : setlist.name)
                                        .font(.body).fontWeight(.medium)
                                    Text("\((setlist.songs ?? []).count) songs")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(setlists[i]) }
                        }
                    }
                }
            }
            .navigationTitle("Setlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) { SetlistEditorView(setlist: nil) }
        }
    }
}

struct SetlistEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let setlist: Setlist?
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Setlist name", text: $name)
                TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(2...4)
            }
            .navigationTitle(setlist == nil ? "New Setlist" : "Edit Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let setlist { name = setlist.name; notes = setlist.notes }
            }
        }
    }

    private func save() {
        let target = setlist ?? {
            let s = Setlist(); context.insert(s); return s
        }()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.notes = notes
        Haptics.success()
        dismiss()
    }
}
