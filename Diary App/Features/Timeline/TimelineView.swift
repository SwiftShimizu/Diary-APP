import SwiftUI
import SwiftData

@MainActor
struct TimelineView: View {
    @EnvironmentObject private var auth: AuthSessionStore
    @StateObject private var store: TimelineStore
    @State private var showingEditor = false
    @State private var editingEntry: EntryEntity?
    @State private var currentAuthorColorHex: String = AuthorProfileStorage().load().colorHex
    private let syncService = SyncService()

    init(repository: EntryRepositoryType) {
        _store = StateObject(wrappedValue: TimelineStore(repository: repository))
    }

    init() {
        self.init(repository: EntryRepository())
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        Group {
            if store.state.entries.isEmpty {
                ContentUnavailableView("No entries yet", systemImage: "book.closed")
            } else {
                List(store.state.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.title)
                            .font(.headline)
                        Text(entry.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Text(dateFormatter.string(from: entry.diaryDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(entry.authorName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color(
                                        hex: entry.authorID == auth.session?.user.id
                                            ? currentAuthorColorHex
                                            : entry.authorColorHex
                                    ).opacity(0.2)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Edit") {
                            editingEntry = entry
                            showingEditor = true
                        }
                        .tint(.blue)

                        Button("Delete", role: .destructive) {
                            store.send(.delete(entry))
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Timeline")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingEntry = nil
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            if let session = auth.session {
                await syncService.sync(session: session)
            }
            store.send(.onAppear)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { newValue in
                    if !newValue { store.clearError() }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    store.clearError()
                }
            },
            message: {
                Text(store.state.errorMessage ?? "")
            }
        )
        .sheet(isPresented: $showingEditor) {
            EntryEditorView(entry: editingEntry) {
                store.send(.reload)
            }
        }
        .onAppear {
            currentAuthorColorHex = AuthorProfileStorage().load().colorHex
        }
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let context = ModelContext(controller.container)
    let sample = EntryEntity(
        diaryDate: Date(),
        title: "Sample Entry",
        body: "This is a preview entry.",
        authorID: "you",
        authorName: "You",
        authorColorHex: "#FF6B6B"
    )
    context.insert(sample)
    try? context.save()

    return TimelineView(repository: EntryRepository(container: controller.container))
        .modelContainer(controller.container)
        .environmentObject(AuthSessionStore())
}
