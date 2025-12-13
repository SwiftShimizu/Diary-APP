import Foundation

/// Stub API client that keeps entries in memory. Replace with real HTTP implementation later.
@MainActor
final class InMemoryEntriesAPI: EntriesAPI {
    static let shared = InMemoryEntriesAPI()

    private var storage: [String: Entry] = [:]

    init() {
        // Seed with one sample entry
        let sample = Entry(
            id: UUID(),
            serverID: "sample-1",
            diaryDate: Date(),
            title: "Welcome",
            body: "This is a stubbed entry from the in-memory API.",
            author: Author(id: "you", displayName: "You", colorHex: "#FF6B6B"),
            attachments: [],
            createdAt: Date(),
            updatedAt: Date(),
            isDeleted: false
        )
        storage[sample.serverID ?? sample.id.uuidString] = sample
    }

    func fetchUpdated(since: Date?, context: EntriesRequestContext?) async throws -> [Entry] {
        // Ignore since/context for the stub; return all non-deleted entries.
        return storage.values.filter { !$0.isDeleted }
    }

    func create(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry {
        var created = entry
        if created.serverID == nil {
            created.serverID = created.id.uuidString
        }
        storage[created.serverID ?? created.id.uuidString] = created
        return created
    }

    func update(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry {
        guard let key = entry.serverID ?? entry.id.uuidString as String? else {
            return try await create(entry, context: context)
        }
        var updated = entry
        updated.updatedAt = Date()
        storage[key] = updated
        return updated
    }

    func delete(serverID: String, context: EntriesRequestContext?) async throws {
        if var existing = storage[serverID] {
            existing.isDeleted = true
            existing.updatedAt = Date()
            storage[serverID] = existing
        }
    }
}
