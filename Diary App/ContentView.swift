import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("Timeline", systemImage: "list.bullet")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
}
