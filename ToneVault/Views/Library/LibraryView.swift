import SwiftUI
import SwiftData

/// Home / Library: your gear plus quick access to favorites and the last-used tone.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager

    @Query(sort: \Gear.dateCreated, order: .reverse) private var gear: [Gear]
    @Query(filter: #Predicate<ToneSetting> { $0.isFavorite },
           sort: \ToneSetting.dateModified, order: .reverse) private var favorites: [ToneSetting]
    @Query(sort: \ToneSetting.dateModified, order: .reverse) private var recentSettings: [ToneSetting]

    @State private var showingNewGear = false
    @State private var showingPaywall = false
    @State private var searchText = ""

    private var lastUsed: ToneSetting? { recentSettings.first }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var filteredGear: [Gear] {
        gear.filter { SearchFilter.gearMatches($0, query: searchText) }
    }

    private var matchingTones: [ToneSetting] {
        recentSettings.filter { SearchFilter.toneMatches($0, query: searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if gear.isEmpty {
                    EmptyStateView(
                        systemImage: "guitars",
                        title: "Your vault is empty",
                        message: "Add your first pedal or amp, then drag its knobs to save a tone. Everything stays on this device — no account, no cloud."
                    ) {
                        Button {
                            addGearTapped()
                        } label: {
                            Label("Add gear", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    listContent
                        .searchable(text: $searchText,
                                    placement: .navigationBarDrawer(displayMode: .automatic),
                                    prompt: "Search gear and tones")
                }
            }
            .navigationTitle("ToneVault")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addGearTapped()
                    } label: {
                        Label("Add gear", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewGear) {
                GearEditorView(gear: nil)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var listContent: some View {
        List {
            if isSearching {
                searchResults
            } else {
                browseSections
            }
        }
    }

    /// Search mode: matching gear and matching tones, flat.
    @ViewBuilder
    private var searchResults: some View {
        if filteredGear.isEmpty && matchingTones.isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
        if !filteredGear.isEmpty {
            Section("Gear") {
                ForEach(filteredGear) { g in
                    NavigationLink {
                        GearDetailView(gear: g)
                    } label: {
                        GearRow(gear: g)
                    }
                }
            }
        }
        if !matchingTones.isEmpty {
            Section("Tones") {
                ForEach(matchingTones) { setting in
                    NavigationLink {
                        ToneSettingDetailView(setting: setting)
                    } label: {
                        ToneSettingRow(setting: setting)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var browseSections: some View {
            if let lastUsed {
                Section("Recall last used") {
                    NavigationLink {
                        ToneSettingDetailView(setting: lastUsed)
                    } label: {
                        ToneSettingRow(setting: lastUsed)
                    }
                }
            }

            if !favorites.isEmpty {
                Section("Favorites") {
                    ForEach(favorites) { setting in
                        NavigationLink {
                            ToneSettingDetailView(setting: setting)
                        } label: {
                            ToneSettingRow(setting: setting)
                        }
                    }
                }
            }

            Section("Gear (\(gear.count))") {
                ForEach(gear) { g in
                    NavigationLink {
                        GearDetailView(gear: g)
                    } label: {
                        GearRow(gear: g)
                    }
                }
                .onDelete(perform: deleteGear)
            }

            if !entitlements.isPro {
                Section {
                    FreeTierBanner(
                        gearCount: gear.count,
                        settingCount: recentSettings.count
                    ) { showingPaywall = true }
                }
            }
    }

    private func addGearTapped() {
        if entitlements.canAddGear(currentCount: gear.count) {
            showingNewGear = true
        } else {
            showingPaywall = true
        }
    }

    private func deleteGear(_ offsets: IndexSet) {
        for index in offsets {
            let g = gear[index]
            FileStorage.deletePhoto(g.photoFilename)
            for s in g.settings ?? [] {
                FileStorage.deletePhoto(s.photoFilename)
                FileStorage.deleteAudio(s.audioFilename)
            }
            context.delete(g)
        }
    }
}

struct GearRow: View {
    let gear: Gear
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: gear.brandColorHex) ?? Color.tvAccent)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName)
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(gear.name.isEmpty ? "Untitled gear" : gear.name)
                    .font(.body).fontWeight(.medium)
                Text("\(gear.type.displayName) · \(gear.template.shortName) · \((gear.settings ?? []).count) tones")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        switch gear.type {
        case .pedal: return "square.stack.3d.up"
        case .amp: return "hifispeaker"
        case .multiFX: return "square.grid.2x2"
        case .other: return "dial.medium"
        }
    }
}

struct ToneSettingRow: View {
    let setting: ToneSetting
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: setting.isFavorite ? "star.fill" : "dial.medium")
                .foregroundStyle(setting.isFavorite ? Color.yellow : Color.tvAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(setting.name.isEmpty ? "Untitled tone" : setting.name)
                    .font(.body).fontWeight(.medium)
                Text(setting.gear?.name ?? "No gear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if setting.audioFilename != nil {
                Image(systemName: "waveform").foregroundStyle(.secondary).font(.caption)
            }
            if setting.photoFilename != nil {
                Image(systemName: "photo").foregroundStyle(.secondary).font(.caption)
            }
        }
    }
}

#if DEBUG
#Preview {
    LibraryView()
        .environmentObject(EntitlementManager())
        .modelContainer(PreviewData.container)
}
#endif
