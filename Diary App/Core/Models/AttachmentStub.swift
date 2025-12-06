import Foundation

struct AttachmentStub: Equatable, Codable, Identifiable {
    var id: UUID = UUID()
    var serverID: String?
    var filename: String
    var mimeType: String
    var size: Int?
    var thumbnailLocalPath: String?
}
