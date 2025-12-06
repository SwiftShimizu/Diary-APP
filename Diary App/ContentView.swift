import SwiftUI

struct ContentView: View {
    @State private var showingEditor = false
    @State private var refreshToken = UUID()
    
    var body: some View {
        NavigationStack {
            TimelineView(refreshTrigger: refreshToken)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingEditor = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingEditor) {
                    EntryEditorView {
                        refreshToken = UUID()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
