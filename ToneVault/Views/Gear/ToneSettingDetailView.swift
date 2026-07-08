import SwiftUI
import SwiftData

/// Read-only recall of a saved tone, with edit / clone / favorite and playback.
struct ToneSettingDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    @Bindable var setting: ToneSetting

    @State private var showingEditor = false
    @State private var showingPaywall = false
    @StateObject private var player = AudioPlayerController()

    private var style: KnobDisplayStyle { KnobDisplayStyle(rawValue: styleRaw) ?? .numeric }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let photo = FileStorage.loadPhoto(setting.photoFilename) {
                    Image(uiImage: photo)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ControlBoardView(
                    controlValues: setting.controlValues ?? [],
                    specs: setting.gear?.controls ?? [],
                    displayStyle: style,
                    isEditable: false
                )

                if let audioURL = FileStorage.audioURL(setting.audioFilename) {
                    Button {
                        player.toggle(url: audioURL)
                    } label: {
                        Label(player.isPlaying ? "Stop clip" : "Play tone clip",
                              systemImage: player.isPlaying ? "stop.circle" : "play.circle")
                    }
                    .buttonStyle(.bordered)
                }

                if !setting.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes").font(.headline)
                        Text(setting.notes).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(setting.name.isEmpty ? "Tone" : setting.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingEditor = true } label: { Label("Edit", systemImage: "pencil") }
                    Button { toggleFavorite() } label: {
                        Label(setting.isFavorite ? "Unfavorite" : "Favorite",
                              systemImage: setting.isFavorite ? "star.slash" : "star")
                    }
                    Button { cloneTapped() } label: { Label("Clone & tweak", systemImage: "plus.square.on.square") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let gear = setting.gear {
                ToneSettingEditorView(gear: gear, setting: setting)
            }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .onDisappear { player.stop() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: setting.gear?.brandColorHex) ?? Color.tvAccent)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "dial.medium").foregroundStyle(.white))
            VStack(alignment: .leading) {
                Text(setting.gear?.name ?? "No gear").font(.headline)
                Text(setting.gear?.template.shortName ?? "").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if setting.isFavorite {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
            }
        }
    }

    private func toggleFavorite() {
        setting.isFavorite.toggle()
        setting.dateModified = Date()
        Haptics.selection()
    }

    private func cloneTapped() {
        guard entitlements.canAddSetting(currentCount: (try? context.fetchCount(FetchDescriptor<ToneSetting>())) ?? 0) else {
            showingPaywall = true; return
        }
        setting.clone(in: context)
        Haptics.success()
    }
}
