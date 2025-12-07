import Foundation

struct AuthorProfile {
    var name: String
    var colorHex: String
}

struct AuthorProfileStorage {
    private static let nameKey = "author_profile_name"
    private static let colorKey = "author_profile_color"
    
    func load() -> AuthorProfile {
        let name = UserDefaults.standard.string(forKey: Self.nameKey) ?? "You"
        let color = UserDefaults.standard.string(forKey: Self.colorKey) ?? "#FF6B6B"
        return AuthorProfile(name: name, colorHex: color)
    }
    
    func save(_ profile: AuthorProfile) {
        UserDefaults.standard.set(profile.name, forKey: Self.nameKey)
        UserDefaults.standard.set(profile.colorHex, forKey: Self.colorKey)
    }
}
