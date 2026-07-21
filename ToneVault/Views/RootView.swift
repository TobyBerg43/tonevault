import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(PrefKey.didSeeWelcome) private var didSeeWelcome = false
    @State private var showingWelcome = false

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "guitars") }

            SongListView()
                .tabItem { Label("Songs", systemImage: "music.note.list") }

            SetlistListView()
                .tabItem { Label("Setlists", systemImage: "list.number") }

            AppSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onAppear {
            if !didSeeWelcome { showingWelcome = true }
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView()
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environmentObject(EntitlementManager())
        .modelContainer(PreviewData.container)
}
#endif
