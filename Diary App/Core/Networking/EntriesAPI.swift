import Foundation

struct EntriesRequestContext {
    let baseURL: URL
    let publishableKey: String
    let accessToken: String
    let userID: String
    let diaryID: String
}

protocol EntriesAPI {
    func fetchUpdated(since: Date?, context: EntriesRequestContext?) async throws -> [Entry]
    func create(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry
    func update(_ entry: Entry, context: EntriesRequestContext?) async throws -> Entry
    func delete(serverID: String, context: EntriesRequestContext?) async throws
}
