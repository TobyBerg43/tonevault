import SwiftUI
import SwiftData

/// Shows a gear's saved tones. Add / clone / open settings; edit the gear itself.
struct GearDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    @Bindable var gear: Gear

    @State private var showingEditGear = false
    @State private var showingNewSetting = false
    @State private var showingPaywall = false

    private var style: KnobDisplayStyle { KnobDisplayStyle(rawValue: styleRaw) ?? .numeric }

    var body: some View {
        List {
            if let photo = FileStorage.loadPhoto(gear.photoFilename) {
                Section {
                    Image(uiImage: photo)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                LabeledContent("Type", value: gear.type.displayName)
                LabeledContent("Layout", value: gear.template.shortName)
                if !gear.notes.isEmpty {
                    Text(gear.notes).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            Section("Saved tones (\(gear.sortedSettings.count))") {
                if gear.sortedSettings.isEmpty {
                    Text("No tones yet. Tap “New tone” to drag the knobs and save your first.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(gear.sortedSettings) { setting in
                    NavigationLink {
                        ToneSettingDetailView(setting: setting)
                    } label: {
                        ToneSettingRow(setting: setting)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            toggleFavorite(setting)
                        } label: {
                            Label("Favorite", systemImage: setting.isFavorite ? "star.slash" : "star")
                        }.tint(.yellow)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            cloneSetting(setting)
                        } label: { Label("Clone", systemImage: "plus.square.on.square") }
                            .tint(.blue)
                    }
                }
                .onDelete(perform: deleteSettings)
            }
        }
        .navigationTitle(gear.name.isEmpty ? "Gear" : gear.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { newSettingTapped() } label: { Label("New tone", systemImage: "plus") }
                    Button { showingEditGear = true } label: { Label("Edit gear", systemImage: "pencil") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                newSettingTapped()
            } label: {
                Label("New tone", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingEditGear) {
            GearEditorView(gear: gear)
        }
        .sheet(isPresented: $showingNewSetting) {
            ToneSettingEditorView(gear: gear, setting: nil)
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private func newSettingTapped() {
        let count = totalSettingCount()
        if entitlements.canAddSetting(currentCount: count) {
            showingNewSetting = true
        } else {
            showingPaywall = true
        }
    }

    private func totalSettingCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<ToneSetting>())) ?? 0
    }

    private func toggleFavorite(_ setting: ToneSetting) {
        setting.isFavorite.toggle()
        setting.dateModified = Date()
        Haptics.selection()
    }

    private func cloneSetting(_ setting: ToneSetting) {
        guard entitlements.canAddSetting(currentCount: totalSettingCount()) else {
            showingPaywall = true; return
        }
        setting.clone(in: context)
        Haptics.success()
    }

    private func deleteSettings(_ offsets: IndexSet) {
        let items = gear.sortedSettings
        for index in offsets {
            let s = items[index]
            FileStorage.deletePhoto(s.photoFilename)
            FileStorage.deleteAudio(s.audioFilename)
            context.delete(s)
        }
    }
}
