import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    private enum Effect { case save(AuthorProfile) }
    
    @Published private(set) var state = SettingsState()
    private let storage: AuthorProfileStorage
    private let palette: [String] = [
        "#FF6B6B", // red
        "#F7B32B", // yellow
        "#34C759", // green
        "#0A84FF", // blue
        "#AF52DE"  // purple
    ]
    
    init(storage: AuthorProfileStorage) {
        self.storage = storage
    }

    convenience init() {
        self.init(storage: AuthorProfileStorage())
    }

    func send(_ intent: SettingsIntent) {
        if let effect = reduce(intent) {
            handle(effect)
        }
    }
    
    private func reduce(_ intent: SettingsIntent) -> Effect? {
        switch intent {
        case .onAppear:
            loadProfile()
        case .updateName(let string):
            updateName(string)
        case .selectColor(let string):
            selectColor(string)
        case .save:
            return beginSave()
        case .clearMessages:
            clearMessages()
        }
        return nil
    }

    private func loadProfile() {
        let profile = storage.load()
        state.name = profile.name
        state.colorHex = profile.colorHex
        state.availableColors = palette
    }

    private func updateName(_ name: String) {
        state.name = name
    }

    private func selectColor(_ color: String) {
        state.colorHex = color
    }

    private func beginSave() -> Effect? {
        guard !state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Name is required"
            return nil
        }
        setSaving(true)
        let profile = AuthorProfile(name: state.name, colorHex: state.colorHex)
        return .save(profile)
    }

    private func clearMessages() {
        state.errorMessage = nil
        state.infoMessage = nil
    }

    private func setSaving(_ flag: Bool) {
        state.isSaving = flag
    }
    
    private func handle(_ effect: Effect) {
        switch effect {
        case .save(let profile):
            storage.save(profile)
            setSaving(false)
            state.infoMessage = "Profile saved"

        }
    }
}
