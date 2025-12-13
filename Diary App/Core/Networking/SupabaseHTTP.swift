import Foundation

enum SupabaseHTTPError: Error {
    case invalidResponse
    case httpStatus(Int, String)
}

struct SupabaseHTTP {
    let baseURL: URL
    let publishableKey: String
    let urlSession: URLSession

    init(
        baseURL: URL,
        publishableKey: String,
        urlSession: URLSession
    ) {
        self.baseURL = baseURL
        self.publishableKey = publishableKey
        self.urlSession = urlSession
    }

    init() {
        self.init(
            baseURL: SupabaseConfig.projectURL,
            publishableKey: SupabaseConfig.publishableKey,
            urlSession: .shared
        )
    }

    func request(
        path: String,
        method: String,
        accessToken: String,
        queryItems: [URLQueryItem] = [],
        jsonBody: Data? = nil,
        prefer: String? = nil
    ) async throws -> Data {
        let url = baseURL
            .appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
            .appending(queryItems: queryItems)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        if let jsonBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonBody
        }

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseHTTPError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SupabaseHTTPError.httpStatus(http.statusCode, body)
        }
        return data
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard !queryItems.isEmpty else { return self }
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }
}
