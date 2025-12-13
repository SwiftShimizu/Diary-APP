import Foundation

@MainActor
final class SupabaseEntriesAPI: EntriesAPI {
    private let http: SupabaseHTTP

    init(http: SupabaseHTTP) {
        self.http = http
    }

    convenience init() {
        self.init(http: SupabaseHTTP())
    }

    func fetchUpdated(since: Date?, context: EntriesRequestContext?) async throws -> [Entry] {
        guard let context else { return [] }

        var query: [URLQueryItem] = [
            URLQueryItem(name: "diary_id", value: "eq.\(context.diaryID)"),
            URLQueryItem(name: "select", value: "id,diary_id,author_id,author_name,author_color_hex,diary_date,title,body,is_deleted,created_at,updated_at"),
            URLQueryItem(name: "order", value: "diary_date.desc,updated_at.desc")
        ]
        if let since {
            let iso = SupabaseDate.formatTimestamp(since)
            query.append(URLQueryItem(name: "updated_at", value: "gte.\(iso)"))
        }

        let data = try await http.request(
            path: "/rest/v1/entries",
            method: "GET",
            accessToken: context.accessToken,
            queryItems: query
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = SupabaseDate.parseTimestamp(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        let rows = try decoder.decode([SupabaseEntryRow].self, from: data)
        return rows.compactMap { $0.toEntry() }
    }

    func create(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry {
        try await upsert(entry, context: context)
    }

    func update(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry {
        try await upsert(entry, context: context)
    }

    func delete(serverID: String, context: EntriesRequestContext?) async throws {
        guard let context else { return }
        let query = [URLQueryItem(name: "id", value: "eq.\(serverID)")]
        let payload = ["is_deleted": true]
        let body = try JSONSerialization.data(withJSONObject: payload, options: [])
        _ = try await http.request(
            path: "/rest/v1/entries",
            method: "PATCH",
            accessToken: context.accessToken,
            queryItems: query,
            jsonBody: body,
            prefer: "return=minimal"
        )
    }

    private func upsert(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry {
        guard let context else { return entry }

        let row = SupabaseEntryUpsertRow.from(entry: entry, context: context)
        let encoder = JSONEncoder()
        let body = try encoder.encode([row])

        let data = try await http.request(
            path: "/rest/v1/entries",
            method: "POST",
            accessToken: context.accessToken,
            queryItems: [URLQueryItem(name: "select", value: "id,diary_id,author_id,author_name,author_color_hex,diary_date,title,body,is_deleted,created_at,updated_at")],
            jsonBody: body,
            prefer: "resolution=merge-duplicates,return=representation"
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = SupabaseDate.parseTimestamp(string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }

        let rows = try decoder.decode([SupabaseEntryRow].self, from: data)
        return rows.first?.toEntry() ?? entry
    }
}

private struct SupabaseEntryRow: Decodable {
    let id: String
    let diary_id: String
    let author_id: String
    let author_name: String?
    let author_color_hex: String?
    let diary_date: String
    let title: String
    let body: String
    let is_deleted: Bool
    let created_at: Date
    let updated_at: Date

    func toEntry() -> Entry? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        guard let diaryDate = SupabaseDate.decodeDiaryDate(diary_date) else { return nil }

        return Entry(
            id: uuid,
            serverID: id,
            diaryDate: diaryDate,
            title: title,
            body: body,
            author: Author(
                id: author_id,
                displayName: author_name ?? "Unknown",
                colorHex: author_color_hex ?? "#FF6B6B"
            ),
            attachments: [],
            createdAt: created_at,
            updatedAt: updated_at,
            isDeleted: is_deleted
        )
    }
}

private struct SupabaseEntryUpsertRow: Encodable {
    let id: String
    let diary_id: String
    let author_id: String
    let author_name: String
    let author_color_hex: String
    let diary_date: String
    let title: String
    let body: String
    let is_deleted: Bool

    static func from(entry: Entry, context: EntriesRequestContext) -> SupabaseEntryUpsertRow {
        let authorID = entry.author.id == "you" ? context.userID : entry.author.id
        return SupabaseEntryUpsertRow(
            id: entry.id.uuidString,
            diary_id: context.diaryID,
            author_id: authorID,
            author_name: entry.author.displayName,
            author_color_hex: entry.author.colorHex,
            diary_date: SupabaseDate.encodeDiaryDate(entry.diaryDate),
            title: entry.title,
            body: entry.body,
            is_deleted: entry.isDeleted
        )
    }
}
