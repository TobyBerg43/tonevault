import SwiftUI

/// In-app copy of the privacy policy, so it exists regardless of external hosting.
/// The identical text lives in Docs/PRIVACY_POLICY.md for you to host for free.
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            Text(PrivacyPolicyText.markdown)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum PrivacyPolicyText {
    /// Rendered as Markdown by SwiftUI Text (headings shown as bold lines).
    static let markdown: LocalizedStringKey = """
    **ToneVault Privacy Policy**

    _Last updated: 2026-01-01_

    **The short version:** ToneVault collects nothing. There is no account, no login, no server, no analytics, and no third-party tracking. Everything you create stays on your device.

    **What we collect:** Nothing. ToneVault does not collect, transmit, or sell any personal data. We have no servers and no way to receive your data.

    **What stays on your device:** The gear, tones, songs, setlists, notes, photos, and audio clips you create are stored locally on your iPhone or iPad. Photos and audio are saved as files in the app's private storage. If you make a backup, that file is written wherever you choose to save it (for example Files or iCloud Drive) — that is your copy, under your control.

    **Camera, photos, and microphone:** These are optional. If you attach a photo or record a tone clip, ToneVault uses the relevant permission only for that action, and the result is stored locally. The entire app works with these permissions denied.

    **Network:** ToneVault does not require an internet connection and makes no network calls to us. The only network activity is Apple's App Store handling your optional one-time "ToneVault Pro" purchase and restore, which is processed by Apple, not by us. We never see your payment details.

    **Analytics and tracking:** None. There is no analytics SDK and no advertising.

    **Children:** ToneVault does not collect data from anyone, including children.

    **Your control:** Because your data lives only on your device, you can delete any item, or delete the app, to remove it. Export a backup at any time from Settings.

    **Changes:** If this policy ever changes, the updated text will appear here in the app and at the hosted URL.

    **Contact:** Questions? Email the address listed on the app's App Store page.

    _Not affiliated with or endorsed by any pedal or amplifier manufacturer._
    """

    /// Plain-text version (no Markdown emphasis) for the hosted file / export.
    static let plain = """
    ToneVault Privacy Policy
    Last updated: 2026-01-01

    The short version: ToneVault collects nothing. There is no account, no login, no server, no analytics, and no third-party tracking. Everything you create stays on your device.

    What we collect: Nothing. ToneVault does not collect, transmit, or sell any personal data. We have no servers and no way to receive your data.

    What stays on your device: The gear, tones, songs, setlists, notes, photos, and audio clips you create are stored locally on your iPhone or iPad. Photos and audio are saved as files in the app's private storage. If you make a backup, that file is written wherever you choose to save it (for example Files or iCloud Drive) — that is your copy, under your control.

    Camera, photos, and microphone: These are optional. If you attach a photo or record a tone clip, ToneVault uses the relevant permission only for that action, and the result is stored locally. The entire app works with these permissions denied.

    Network: ToneVault does not require an internet connection and makes no network calls to us. The only network activity is Apple's App Store handling your optional one-time "ToneVault Pro" purchase and restore, which is processed by Apple, not by us. We never see your payment details.

    Analytics and tracking: None. There is no analytics SDK and no advertising.

    Children: ToneVault does not collect data from anyone, including children.

    Your control: Because your data lives only on your device, you can delete any item, or delete the app, to remove it. Export a backup at any time from Settings.

    Changes: If this policy ever changes, the updated text will appear here in the app and at the hosted URL.

    Contact: Questions? Email the address listed on the app's App Store page.

    Not affiliated with or endorsed by any pedal or amplifier manufacturer.
    """
}
