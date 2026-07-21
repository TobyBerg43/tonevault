import SwiftUI
import SwiftData

/// First-launch welcome: explains the app in three lines and puts a live,
/// draggable knob on screen immediately — the core interaction is the pitch.
struct WelcomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.didSeeWelcome) private var didSeeWelcome = false

    @State private var demoValue: Double = 6.5

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.tvAccent)
                    Text("Never lose a tone again")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Save the exact knob positions of your pedals and amps — organized by song and setlist.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // Live demo — this is the app in one gesture.
                VStack(spacing: 8) {
                    KnobView(value: $demoValue, label: "Drive", displayStyle: .numeric)
                    Text("Try it — drag the knob up or down")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 14) {
                    bullet("guitars", "Build your gear from generic layouts — 3-knob pedal, amp head, graphic EQ and more.")
                    bullet("music.note.list", "Group tones into songs, songs into setlists.")
                    bullet("play.rectangle.fill", "Stage mode: huge, high-contrast settings for dark venues. The screen never locks mid-gig.")
                    bullet("lock.shield", "100% offline. No account, no cloud. Your data is yours.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    Button {
                        SampleContent.install(in: context)
                        Haptics.success()
                        finish()
                    } label: {
                        Text("Start with an example pedal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Start from scratch") {
                        finish()
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .interactiveDismissDisabled()
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.tvAccent)
                .frame(width: 26)
        }
    }

    private func finish() {
        didSeeWelcome = true
        dismiss()
    }
}

#if DEBUG
#Preview {
    WelcomeView()
        .modelContainer(PreviewData.container)
}
#endif
