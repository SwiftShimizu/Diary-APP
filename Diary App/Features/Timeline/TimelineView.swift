import SwiftUI
import SwiftData

@MainActor
struct TimelineView: View {
    @StateObject private var store: TimelineStore
    private let refreshTrigger: UUID

    init(repository: EntryRepositoryType, refreshTrigger: UUID = UUID()) {
        _store = StateObject(wrappedValue: TimelineStore(repository: repository))
        self.refreshTrigger = refreshTrigger
    }

    init(refreshTrigger: UUID = UUID()) {
        self.init(repository: EntryRepository(), refreshTrigger: refreshTrigger)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
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
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Timeline")
            .task { store.send(.onAppear) }
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
        }
        .onChange(of: refreshTrigger) { _ in
            store.send(.reload)
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
}
