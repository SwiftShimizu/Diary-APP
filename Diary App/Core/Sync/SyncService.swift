import Foundation

@MainActor
final class SyncService {
    private let repository: EntryRepositoryType
    private let api: EntriesAPI
    private let diaryClient: SupabaseDiaryClient
    private let metadata: SyncMetadataStorage

    init(
        repository: EntryRepositoryType,
        api: EntriesAPI,
        diaryClient: SupabaseDiaryClient,
        metadata: SyncMetadataStorage
    ) {
        self.repository = repository
        self.api = api
        self.diaryClient = diaryClient
        self.metadata = metadata
    }

    convenience init() {
        self.init(
            repository: EntryRepository(),
            api: SupabaseEntriesAPI(),
            diaryClient: SupabaseDiaryClient(),
            metadata: SyncMetadataStorage()
        )
    }

    /// Push local changes then pull remote changes.
    func sync(session: SupabaseSession) async {
        do {
            guard let diaryID = try await diaryClient.fetchMyDiaryIDs(accessToken: session.accessToken).first else {
                print("No diary membership found for user \(session.user.id)")
                return
            }

            let context = EntriesRequestContext(
                baseURL: SupabaseConfig.projectURL,
                publishableKey: SupabaseConfig.publishableKey,
                accessToken: session.accessToken,
                userID: session.user.id,
                diaryID: diaryID
            )

            let lastSync = metadata.loadLastSync(diaryID: diaryID)
            try await pushLocalChanges(context: context, since: lastSync)

            let remoteEntries = try await api.fetchUpdated(since: lastSync, context: context)
            try apply(remoteEntries)
            metadata.saveLastSync(Date(), diaryID: diaryID)
        } catch {
            print("Sync failed: \(error)")
        }
    }

    private func pushLocalChanges(context: EntriesRequestContext, since: Date?) async throws {
        let all = try repository.fetchAll(includeDeleted: true)
        let candidates: [EntryEntity]
        if let since {
            candidates = all.filter { $0.updatedAt > since }
        } else {
            candidates = all
        }

        for entity in candidates {
            let entry = makeEntry(from: entity, context: context)
            if entity.isDeleted {
                try await api.delete(serverID: entry.id.uuidString, context: context)
            } else {
                _ = try await api.create(entry, context: context)
            }
        }
    }

    private func apply(_ remoteEntries: [Entry]) throws {
        let localAll = try repository.fetchAll(includeDeleted: true)

        for entry in remoteEntries {
            if let existing = localAll.first(where: { $0.id == entry.id }) {
                overwrite(entity: existing, with: entry)
                try repository.update(existing)
            } else {
                let newEntity = makeEntity(from: entry)
                try repository.insert(newEntity)
            }
        }
    }

    private func overwrite(entity: EntryEntity, with entry: Entry) {
        entity.serverID = entry.serverID
        entity.diaryDate = entry.diaryDate
        entity.title = entry.title
        entity.body = entry.body
        entity.authorID = entry.author.id
        entity.authorName = entry.author.displayName
        entity.authorColorHex = entry.author.colorHex
        entity.isDeleted = entry.isDeleted
        entity.updatedAt = entry.updatedAt
        entity.createdAt = entry.createdAt
    }

    private func makeEntity(from entry: Entry) -> EntryEntity {
        EntryEntity(
            id: entry.id,
            serverID: entry.id.uuidString,
            diaryDate: entry.diaryDate,
            title: entry.title,
            body: entry.body,
            authorID: entry.author.id,
            authorName: entry.author.displayName,
            authorColorHex: entry.author.colorHex,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            isDeleted: entry.isDeleted
        )
    }

    private func makeEntry(from entity: EntryEntity, context: EntriesRequestContext) -> Entry {
        let authorID = entity.authorID == "you" ? context.userID : entity.authorID
        return Entry(
            id: entity.id,
            serverID: entity.id.uuidString,
            diaryDate: entity.diaryDate,
            title: entity.title,
            body: entity.body,
            author: Author(
                id: authorID,
                displayName: entity.authorName,
                colorHex: entity.authorColorHex
            ),
            attachments: [],
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            isDeleted: entity.isDeleted
        )
    }
}

struct SyncMetadataStorage {
    private let prefix = "sync_last_at_"

    func loadLastSync(diaryID: String) -> Date? {
        UserDefaults.standard.object(forKey: prefix + diaryID) as? Date
    }

    func saveLastSync(_ date: Date, diaryID: String) {
        UserDefaults.standard.set(date, forKey: prefix + diaryID)
    }
}
