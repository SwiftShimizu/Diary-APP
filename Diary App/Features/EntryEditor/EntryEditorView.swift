import SwiftUI

@MainActor
struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store: EntryEditorStore
    var onSaved: (() -> Void)?

    init(repository: EntryRepositoryType, onSaved: (() -> Void)? = nil) {
        _store = StateObject(wrappedValue: EntryEditorStore(repository: repository))
        self.onSaved = onSaved
    }

    init(onSaved: (() -> Void)? = nil) {
        self.init(repository: EntryRepository(), onSaved: onSaved)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Title", text: Binding(
                        get: { store.state.title },
                        set: { store.send(.updateTitle($0)) }
                    ))
                    TextField("Body", text: Binding(
                        get: { store.state.body },
                        set: { store.send(.updateBody($0)) }
                    ), axis: .vertical)
                        .lineLimit(4...8)
                    DatePicker("Date", selection: Binding(
                        get: { store.state.diaryDate },
                        set: { store.send(.updateDate($0)) }
                    ), displayedComponents: .date)
                }

                Section("Author") {
                    TextField("Name", text: Binding(
                        get: { store.state.authorName },
                        set: { store.send(.updateAuthorName($0)) }
                    ))
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.save) {
                            onSaved?()
                            dismiss()
                        }
                    }
                    .disabled(store.state.isSaving)
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { store.state.errorMessage != nil },
                    set: { newValue in if !newValue { store.send(.clearError) } }
                ),
                actions: { Button("OK", role: .cancel) { store.send(.clearError) } },
                message: { Text(store.state.errorMessage ?? "") }
            )
        }
    }
}

#Preview {
    EntryEditorView()
}
