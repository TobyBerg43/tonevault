import SwiftUI
import SwiftData

@main
struct ToneVaultApp: App {
    @StateObject private var entitlements = EntitlementManager()

    /// Single shared container for all local models. Pure on-device; no CloudKit.
    let container: ModelContainer = {
        let schema = Schema([
            Gear.self,
            ToneSetting.self,
            ControlValue.self,
            Song.self,
            Setlist.self
        ])
        // Explicit local-only configuration. (No `.automatic` CloudKit database.)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // A failure here means an unrecoverable store problem; surface loudly in dev.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(entitlements)
                .tint(Color.tvAccent)
        }
        .modelContainer(container)
    }
}
