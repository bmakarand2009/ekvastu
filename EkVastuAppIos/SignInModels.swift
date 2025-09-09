import Foundation

// MARK: - Sign In Request Model
struct SignInRequest: Codable {
    let orgId: String
    let userId: String
    let password: String
    let rememberMe: Bool
}

// MARK: - Sign In Response Model
struct SignInResponse: Codable {
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

// MARK: - Contact Model
struct Contact: Codable {
    let id: String
    let guId: String
    let email: String
    let fullName: String
    let name: String
    let lastName: String?
    let phone: String?
    let picture: String?
    let imageUrl: String?
    let isEmailVerified: Bool
    let isFirstLogin: Bool
    let isAdminVerified: Bool
    let hasAcceptedTerms: Bool
    let isLocalPicture: Bool
    let balance: Double?
    let description: String?
    let grnNumber: String?
}

// MARK: - Tenant Model
struct Tenant: Codable {
    let name: String
    let orgId: String
    let masterOrgId: String
    let masterOrgGuId: String
    let phone: String?
    let fromEmail: String?
    let fromEmailName: String?
    let customDomain: String?
    let country: String
    let timezone: String
    let dateFormat: String
    let invoiceDateFormat: String
    let environmentName: String
    let isNewClient: Bool
    let isNewTenant: Bool
    let isMasterFranchise: Bool
    let smallLogo: String?
    let bigLogo: String?
    let cloudinaryCloudName: String?
    let cloudinaryPreset: String?
    let address: Address?
    
    struct Address: Codable {
        let line1: String?
        let line2: String?
        let state: String?
        let zip: String?
    }
}

// MARK: - API Error Response Model
struct APIErrorResponse: Codable {
    let success: Bool
    let message: String
    let error: String?
    let code: Int?
}
