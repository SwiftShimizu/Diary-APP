import Foundation
import SwiftData
import Combine

@MainActor
final class TimelineStore: ObservableObject {
    @Published private(set) var state = TimelineState()
    private let repository: EntryRepositoryType

    init(repository: EntryRepositoryType) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: EntryRepository())
    }

    func load() {
        do {
            state.entries = try repository.fetchAll()
            state.errorMessage = nil
        } catch {
            state.errorMessage = "Failed to load entries: \(error.localizedDescription)"
        }
    }

    func clearError() {
        state.errorMessage = nil
    }
}
