import SwiftUI
import SwiftData

struct RootView: View {
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
    }
}

#if DEBUG
#Preview {
    RootView()
        .environmentObject(EntitlementManager())
        .modelContainer(PreviewData.container)
}
#endif
