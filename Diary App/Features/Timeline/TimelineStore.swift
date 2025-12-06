import Foundation
import SwiftData
import Combine

@MainActor
final class TimelineStore: ObservableObject {
    private enum Effect {
        case load
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
        }
    }

    private func handle(_ effect: Effect) {
        switch effect {
        case .load:
            load()
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

    func clearError() {
        state.errorMessage = nil
    }
}
