import SwiftUI

@MainActor
struct LoginView: View {
    @EnvironmentObject private var auth: AuthSessionStore
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                if let errorMessage = auth.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Sign In") {
                        Task { await auth.signIn(email: email, password: password) }
                    }
                    .disabled(auth.isLoading)

                    Button("Sign Up") {
                        Task { await auth.signUp(email: email, password: password) }
                    }
                    .disabled(auth.isLoading)
                }
            }
            .navigationTitle("Login")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthSessionStore())
}

