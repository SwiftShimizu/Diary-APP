import Foundation
import Combine

@MainActor
final class AuthSessionStore: ObservableObject {
    @Published private(set) var session: SupabaseSession?
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authClient: SupabaseAuthClient
    private let storage = AuthSessionStorage()

    init(authClient: SupabaseAuthClient) {
        self.authClient = authClient
        self.session = storage.load()
    }

    convenience init() {
        self.init(authClient: SupabaseAuthClient())
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let newSession = try await authClient.signIn(email: email, password: password)
            session = newSession
            storage.save(newSession)
            errorMessage = nil
        } catch {
            errorMessage = "Login failed: \(error)"
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authClient.signUp(email: email, password: password)
            errorMessage = "Sign up complete. Please sign in."
        } catch {
            errorMessage = "Sign up failed: \(error)"
        }
    }

    func signOut() {
        session = nil
        storage.clear()
    }
}

private struct AuthSessionStorage {
    private let key = "supabase_session_v1"

    func load() -> SupabaseSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SupabaseSession.self, from: data)
    }

    func save(_ session: SupabaseSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
