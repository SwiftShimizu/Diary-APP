import Foundation
import SwiftData

protocol EntryRepositoryType {
    func fetchAll() throws -> [EntryEntity]
    func insert(_ entry: EntryEntity) throws
    func update(_ entry: EntryEntity) throws
    func softDelete(_ entry: EntryEntity) throws
}

@MainActor
final class EntryRepository: EntryRepositoryType {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    convenience init() {
        self.init(container: PersistenceController.shared.container)
    }

    func fetchAll() throws -> [EntryEntity] {
        let descriptor = FetchDescriptor<EntryEntity>(sortBy: [SortDescriptor(\.diaryDate, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func insert(_ entry: EntryEntity) throws {
        context.insert(entry)
        try context.save()
    }

    func update(_ entry: EntryEntity) throws {
        entry.updatedAt = Date()
        try context.save()
    }

    func softDelete(_ entry: EntryEntity) throws {
        entry.isDeleted = true
        entry.updatedAt = Date()
        try context.save()
    }
}
