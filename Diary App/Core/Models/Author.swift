import Foundation

struct Author: Equatable, Codable, Identifiable {
    let id: String
    var displayName: String
    var colorHex: String
}
