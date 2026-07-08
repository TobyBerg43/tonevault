import Foundation

/// Keys for lightweight preferences persisted in UserDefaults.
/// (UserDefaults usage is declared in PrivacyInfo.xcprivacy with reason CA92.1.)
enum PrefKey {
    static let knobDisplayStyle = "knobDisplayStyle"
    static let didSeeWelcome = "didSeeWelcome"
}
