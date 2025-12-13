import Foundation

enum SupabaseAuthError: Error {
    case invalidResponse
    case httpStatus(Int, String)
}

@MainActor
final class SupabaseAuthClient {
    private let baseURL: URL
    private let publishableKey: String
    private let urlSession: URLSession

    init(
        baseURL: URL,
        publishableKey: String,
        urlSession: URLSession
    ) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.urlSession = urlSession
    }

    convenience init() {
        self.init(
            baseURL: SupabaseConfig.projectURL,
            publishableKey: SupabaseConfig.publishableKey,
            urlSession: .shared
        )
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("token")
            .appending(queryItems: [URLQueryItem(name: "grant_type", value: "password")])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseAuthError.httpStatus(http.statusCode, body)
        }

        let decoder = JSONDecoder()
        let token = try decoder.decode(SupabaseTokenResponse.self, from: data)
        return token.toSession()
    }

    func signUp(email: String, password: String) async throws {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("v1")
            .appendingPathComponent("signup")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

        let payload = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseAuthError.httpStatus(http.statusCode, body)
        }
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }
}
