import Foundation
import SwiftData
import Combine

@MainActor
final class EntryEditorStore: ObservableObject {
    private enum Effect {
        case save(EntryEntity)
    }

    @Published private(set) var state = EntryEditorState()
    private let repository: EntryRepositoryType

    init(repository: EntryRepositoryType) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: EntryRepository())
    }

    func send(_ intent: EntryEditorIntent, onSaved: (() -> Void)? = nil) {
        if let effect = reduce(intent) {
            handle(effect, onSaved: onSaved)
        }
    }

    private func reduce(_ intent: EntryEditorIntent) -> Effect? {
        switch intent {
        case .updateTitle(let text):
            state.title = text
        case .updateBody(let text):
            state.body = text
        case .updateDate(let date):
            state.diaryDate = date
        case .updateAuthorName(let text):
            state.authorName = text
        case .save:
            let trimmed = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                state.errorMessage = "Title is required."
                return nil
            }
            state.isSaving = true
            let entry = EntryEntity(
                diaryDate: state.diaryDate,
                title: state.title,
                body: state.body,
                authorID: state.authorID,
                authorName: state.authorName,
                authorColorHex: state.authorColorHex
            )
            return .save(entry)
        case .clearError:
            state.errorMessage = nil
        }
        return nil
    }

    private func handle(_ effect: Effect, onSaved: (() -> Void)?) {
        switch effect {
        case .save(let entry):
            do {
                try repository.insert(entry)
                state.isSaving = false
                onSaved?()
            } catch {
                state.isSaving = false
                state.errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
}
