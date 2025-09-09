import Foundation

// MARK: - Google Login Request Model
struct GoogleLoginRequest: Codable {
    let tid: String
    let orgId: String
    let idToken: String
}

// MARK: - Google Login Response Model
struct GoogleLoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let email: String
    let isNewProfile: Bool
    let role: String
    let contact: Contact
    let tenant: Tenant?
    let orgList: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case email
        case isNewProfile
        case role
        case contact
        case tenant
        case orgList
    }
}
