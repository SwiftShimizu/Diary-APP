import SwiftUI
import SwiftData

@main
struct Diary_AppApp: App {
    @StateObject private var auth = AuthSessionStore()

    var body: some Scene {
        WindowGroup {
            if auth.session != nil {
                ContentView()
                    .environmentObject(auth)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
