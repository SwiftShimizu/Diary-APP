import Foundation

struct SupabaseUser: Codable, Equatable {
    let id: String
    let email: String?
}

struct SupabaseSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: SupabaseUser
}

struct SupabaseTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let token_type: String
    let expires_in: Int
    let user: SupabaseUser

    func toSession() -> SupabaseSession {
        SupabaseSession(
            accessToken: access_token,
            refreshToken: refresh_token,
            tokenType: token_type,
            expiresIn: expires_in,
            user: user
        )
    }
}
