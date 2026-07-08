import SwiftUI

struct AboutView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "dial.medium.fill")
                        .font(.system(size: 52)).foregroundStyle(.tint)
                    Text("ToneVault").font(.title2.bold())
                    Text("Version \(version)").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section {
                Text("ToneVault saves the exact knob positions of your pedals and amps, organized by song and setlist, so you can always recall a tone after tweaking.")
                Text("100% offline. No account, no cloud, no camera scanning. Works in a windowless studio in airplane mode. Your data is yours forever.")
            }

            Section("Legal") {
                Text("Not affiliated with or endorsed by any pedal or amplifier manufacturer. All gear names are entered by you. ToneVault ships no manufacturer logos, trademarks, or product database.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
