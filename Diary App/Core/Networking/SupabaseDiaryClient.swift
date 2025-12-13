import Foundation

struct SupabaseDiaryMembershipRow: Decodable {
    let diary_id: String
}

struct SupabaseDiaryClient {
    private let http: SupabaseHTTP

    init(http: SupabaseHTTP) {
        self.http = http
    }

    init() {
        self.http = SupabaseHTTP()
    }

    func fetchMyDiaryIDs(accessToken: String) async throws -> [String] {
        let data = try await http.request(
            path: "/rest/v1/diary_members",
            method: "GET",
            accessToken: accessToken,
            queryItems: [URLQueryItem(name: "select", value: "diary_id")]
        )
        let decoder = JSONDecoder()
        let rows = try decoder.decode([SupabaseDiaryMembershipRow].self, from: data)
        return rows.map(\.diary_id)
    }
}
