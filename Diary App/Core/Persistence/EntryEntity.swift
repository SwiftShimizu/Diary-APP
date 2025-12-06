import Foundation
import SwiftData

@Model
final class EntryEntity {
    @Attribute(.unique) var id: UUID
    var serverID: String?
    var diaryDate: Date
    var title: String
    var body: String
    var authorID: String
    var authorName: String
    var authorColorHex: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool

    init(
        id: UUID = UUID(),
        serverID: String? = nil,
        diaryDate: Date,
        title: String,
        body: String,
        authorID: String,
        authorName: String,
        authorColorHex: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.serverID = serverID
        self.diaryDate = diaryDate
        self.title = title
        self.body = body
        self.authorID = authorID
        self.authorName = authorName
        self.authorColorHex = authorColorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}
