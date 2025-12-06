import Foundation

struct Entry: Equatable, Codable, Identifiable {
    var id: UUID = UUID()          // local-only; stays overridable on decode
    var serverID: String?          // after sync
    var diaryDate: Date
    var title: String
    var body: String
    var author: Author
    var attachments: [AttachmentStub] = []

    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool = false
}
