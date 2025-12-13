import SwiftUI

@MainActor
struct SettingsView: View {
    @StateObject private var store = SettingsStore()

    var body: some View {
        Form {
            Section("Author") {
                TextField(
                    "Display Name",
                    text: Binding(
                        get: { store.state.name },
                        set: { store.send(.updateName($0)) }
                    )
                )
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.state.availableColors, id: \.self) { hex in
                            Button {
                                store.send(.selectColor(hex))
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(hex == store.state.colorHex ? Color.primary.opacity(0.6) : .clear, lineWidth: 2)
                                        )
                                    if hex == store.state.colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let info = store.state.infoMessage {
                Section {
                    Text(info)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.send(.save)
                }
                .disabled(store.state.isSaving)
            }
        }
        .task { store.send(.onAppear) }
        .alert(
            "Error",
            isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { newValue in
                    if !newValue { store.send(.clearMessages) }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    store.send(.clearMessages)
                }
            },
            message: {
                Text(store.state.errorMessage ?? "")
            }
        )
        .onChange(of: store.state.infoMessage) { _, message in
            guard message != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                store.send(.clearMessages)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
