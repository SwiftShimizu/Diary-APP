import Foundation
import SwiftData
import Combine

@MainActor
final class EntryEditorStore: ObservableObject {
    private enum Effect {
        case saveNew(EntryEntity)
        case update(EntryEntity)
    }

    @Published private(set) var state = EntryEditorState()
    private let repository: EntryRepositoryType
    private var editingEntry: EntryEntity?

    init(
        repository: EntryRepositoryType,
        editingEntry: EntryEntity? = nil,
        profileStorage: AuthorProfileStorage
    ) {
        self.repository = repository
        self.editingEntry = editingEntry

        if let entry = editingEntry {
            state = EntryEditorState(
                title: entry.title,
                body: entry.body,
                diaryDate: entry.diaryDate,
                authorName: entry.authorName,
                authorID: entry.authorID,
                authorColorHex: entry.authorColorHex,
                errorMessage: nil,
                isSaving: false
            )
        } else {
            let profile = profileStorage.load()
            state.authorName = profile.name
            state.authorColorHex = profile.colorHex
        }
    }

    convenience init(editingEntry: EntryEntity? = nil) {
        self.init(
            repository: EntryRepository(),
            editingEntry: editingEntry,
            profileStorage: AuthorProfileStorage()
        )
    }

    func send(_ intent: EntryEditorIntent, onSaved: (() -> Void)? = nil) {
        if let effect = reduce(intent) {
            handle(effect, onSaved: onSaved)
        }
    }

    private func reduce(_ intent: EntryEditorIntent) -> Effect? {
        switch intent {
        case .setCurrentUserID(let userID):
            setCurrentUserID(userID)
        case .updateTitle(let text):
            updateTitle(text)
        case .updateBody(let text):
            updateBody(text)
        case .updateDate(let date):
            updateDate(date)
        case .updateAuthorName(let text):
            updateAuthorName(text)
        case .save:
            return beginSave()
        case .clearError:
            clearError()
        }
        return nil
    }

    private func setCurrentUserID(_ userID: String) {
        if editingEntry == nil {
            state.authorID = userID
        }
    }

    private func updateTitle(_ text: String) {
        state.title = text
    }

    private func updateBody(_ text: String) {
        state.body = text
    }

    private func updateDate(_ date: Date) {
        state.diaryDate = date
    }

    private func updateAuthorName(_ text: String) {
        state.authorName = text
    }

    private func beginSave() -> Effect? {
        let trimmed = state.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state.errorMessage = "Title is required."
            return nil
        }
        setSaving(true)
        if let entry = editingEntry {
            entry.title = state.title
            entry.body = state.body
            entry.diaryDate = state.diaryDate
            entry.authorName = state.authorName
            entry.authorID = state.authorID
            entry.authorColorHex = state.authorColorHex
            return .update(entry)
        } else {
            let entry = EntryEntity(
                diaryDate: state.diaryDate,
                title: state.title,
                body: state.body,
                authorID: state.authorID,
                authorName: state.authorName,
                authorColorHex: state.authorColorHex
            )
            return .saveNew(entry)
        }
    }

    private func clearError() {
        state.errorMessage = nil
    }

    private func setSaving(_ flag: Bool) {
        state.isSaving = flag
    }

    private func handle(_ effect: Effect, onSaved: (() -> Void)?) {
        switch effect {
        case .saveNew(let entry):
            do {
                try repository.insert(entry)
                setSaving(false)
                onSaved?()
            } catch {
                setSaving(false)
                state.errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        case .update(let entry):
            do {
                try repository.update(entry)
                setSaving(false)
                onSaved?()
            } catch {
                setSaving(false)
                state.errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
}
