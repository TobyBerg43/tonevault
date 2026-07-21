import SwiftUI

/// Full-screen, high-contrast live-performance view.
///
/// Built for a dark stage: pure black background, huge type, amber values,
/// swipe left/right to move between songs in the setlist, and the screen
/// never auto-locks while it is open (idle timer disabled).
struct StageView: View {
    let songs: [Song]
    let title: String
    let style: KnobDisplayStyle
    var startIndex: Int = 0

    @State private var index: Int = 0
    @Environment(\.dismiss) private var dismiss

    /// High-visibility amber for values — reads from meters away in the dark.
    static let valueColor = Color(red: 1.0, green: 0.72, blue: 0.20)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if songs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 44))
                        .foregroundStyle(.gray)
                    Text("No songs in this setlist yet.")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }
            } else {
                TabView(selection: $index) {
                    ForEach(Array(songs.enumerated()), id: \.element.id) { i, song in
                        StageSongPage(song: song, position: i + 1, total: songs.count, style: style)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .toolbar {
            if songs.count > 1 {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        withAnimation { index = max(index - 1, 0) }
                        Haptics.selection()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(index == 0)
                    .accessibilityLabel("Previous song")

                    Button {
                        withAnimation { index = min(index + 1, songs.count - 1) }
                        Haptics.selection()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(index == songs.count - 1)
                    .accessibilityLabel("Next song")
                }
            }
        }
        .onAppear {
            index = min(max(startIndex, 0), max(songs.count - 1, 0))
            // Never let the screen lock mid-gig.
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var navTitle: String {
        guard songs.count > 1 else { return title }
        return "\(index + 1) of \(songs.count)"
    }
}

/// One song's full rig, laid out stage-readable.
struct StageSongPage: View {
    let song: Song
    let position: Int
    let total: Int
    let style: KnobDisplayStyle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title block
                VStack(alignment: .leading, spacing: 6) {
                    Text("#\(position)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(StageView.valueColor)
                    Text(song.title.isEmpty ? "Untitled" : song.title)
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)
                    if let artist = song.artist, !artist.isEmpty {
                        Text(artist)
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }

                if !song.notes.isEmpty {
                    Text(song.notes)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }

                if song.sortedSettings.isEmpty {
                    Text("No tones added to this song.")
                        .font(.title3)
                        .foregroundStyle(.gray)
                }

                ForEach(song.sortedSettings) { setting in
                    StageGearCard(setting: setting, style: style)
                }

                if total > 1 {
                    Text(position < total ? "Swipe for next song" : "Last song")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .padding(.bottom, 32)
        }
    }
}

/// One gear's tone on the stage page: gear name, tone name, huge label→value rows.
private struct StageGearCard: View {
    let setting: ToneSetting
    let style: KnobDisplayStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(Color(hex: setting.gear?.brandColorHex) ?? Color.tvAccent)
                    .frame(width: 14, height: 14)
                Text(setting.gear?.name ?? "Gear")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Spacer()
                Text(setting.name)
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }

            ForEach(setting.sortedControlValues) { cv in
                HStack(alignment: .firstTextBaseline) {
                    Text(cv.label)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text(valueString(cv))
                        .font(.system(size: 30, weight: .bold).monospacedDigit())
                        .foregroundStyle(StageView.valueColor)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func valueString(_ cv: ControlValue) -> String {
        let spec = setting.gear?.controls.first { $0.id == cv.controlIndex }
        return ControlValueFormatter.string(for: cv.value, kind: cv.kind, style: style,
                                            selectorPositions: spec?.selectorPositions ?? 3)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        StageView(songs: [], title: "Stage", style: .numeric)
    }
    .modelContainer(PreviewData.container)
}
#endif
