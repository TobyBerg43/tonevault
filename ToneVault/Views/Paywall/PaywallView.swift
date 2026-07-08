import SwiftUI

/// App Store Guideline 3.1.2–compliant paywall:
///  - clearly states it's a ONE-TIME purchase (not a subscription)
///  - shows the price and exactly what unlocks
///  - includes tappable Terms of Use (EULA) and Privacy Policy links (in-binary)
struct PaywallView: View {
    @EnvironmentObject private var entitlements: EntitlementManager
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false

    private let benefits: [(String, String)] = [
        ("infinity", "Unlimited gear, tones, songs & setlists"),
        ("waveform", "Attach audio clips of your tones"),
        ("doc.richtext", "Export printable PDF rig cheat-sheets"),
        ("lock.open", "One-time unlock — yours forever")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(benefits, id: \.1) { benefit in
                            Label {
                                Text(benefit.1).font(.body)
                            } icon: {
                                Image(systemName: benefit.0)
                                    .foregroundStyle(.tint)
                                    .frame(width: 28)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))

                    freeTierNote

                    purchaseButton

                    Button("Restore Purchases") {
                        Task { await runRestore() }
                    }
                    .font(.subheadline)

                    legalLinks

                    if let error = entitlements.purchaseError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("ToneVault Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: entitlements.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "dial.medium.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("Unlock the full vault")
                .font(.title2.bold())
            Text("A single one-time purchase. **Not a subscription** — no recurring charges, ever.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var freeTierNote: some View {
        Text("Backup, restore and full export are always free — your tones are yours whether or not you upgrade.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var purchaseButton: some View {
        Button {
            Task { await runPurchase() }
        } label: {
            HStack {
                if isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text("Unlock Pro — \(entitlements.displayPrice) once")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isWorking)
    }

    private var legalLinks: some View {
        HStack(spacing: 6) {
            Link("Terms of Use (EULA)", destination: LegalLinks.eula)
            Text("·").foregroundStyle(.secondary)
            Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
        }
        .font(.footnote)
    }

    private func runPurchase() async {
        isWorking = true
        await entitlements.purchase()
        isWorking = false
    }

    private func runRestore() async {
        isWorking = true
        await entitlements.restore()
        isWorking = false
    }
}

/// Central place for the legal URLs used across the paywall and Settings.
enum LegalLinks {
    /// Apple's standard EULA (used because we ship no custom website).
    static let eula = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Free-hosted privacy URL (GitHub Pages). The same text is also shown
    /// in-app under Settings → Privacy.
    static let privacyPolicy = URL(string: "https://tobyberg43.github.io/tonevault/privacy.html")!
}

#if DEBUG
#Preview {
    PaywallView().environmentObject(EntitlementManager())
}
#endif
