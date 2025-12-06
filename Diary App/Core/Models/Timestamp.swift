import Foundation

struct Timestamp: Equatable, Codable {
    var createdAt: Date
    var updatedAt: Date
}
typealias EntryID = UUID
