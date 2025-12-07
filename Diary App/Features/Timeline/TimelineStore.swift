import Foundation
import SwiftData
import Combine

@MainActor
final class TimelineStore: ObservableObject {
    private enum Effect {
        case load
        case delete(EntryEntity)
    }

    @Published private(set) var state = TimelineState()
    private let repository: EntryRepositoryType

    init(repository: EntryRepositoryType) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: EntryRepository())
    }

    func send(_ intent: TimelineIntent) {
        if let effect = reduce(intent) {
            handle(effect)
        }
    }

    private func reduce(_ intent: TimelineIntent) -> Effect? {
        switch intent {
        case .onAppear, .reload:
            return .load
        case .delete(let entry):
            return .delete(entry)
        }
    }

    private func handle(_ effect: Effect) {
        switch effect {
        case .load:
            load()
        case .delete(let entry):
            delete(entry)
        }
    }

    private func load() {
        do {
            state.entries = try repository.fetchAll()
            state.errorMessage = nil
        } catch {
            state.errorMessage = "Failed to load entries: \(error.localizedDescription)"
        }
    }

    private func delete(_ entry: EntryEntity) {
        do {
            try repository.softDelete(entry)
            load()
        } catch {
            state.errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }

    func clearError() {
        state.errorMessage = nil
    }
}
