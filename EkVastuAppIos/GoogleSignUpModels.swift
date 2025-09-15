import Foundation

// MARK: - Google Sign Up Request Model
struct GoogleSignUpRequest: Codable {
    let idToken: String
    let tid: String
    let orgId: String
    let name: String
    let lastName: String?
    let phone: String?
    
    // Initialize with required and optional parameters
    init(
        idToken: String,
        tenantId: String, // Parameter name remains the same for compatibility
        orgId: String = "PostFix", // Default value for orgId
        name: String,
        lastName: String? = nil,
        phone: String? = nil
    ) {
        self.idToken = idToken
        self.tid = tenantId // Map tenantId parameter to tid property
        self.orgId = orgId
        self.name = name
        self.lastName = lastName
        self.phone = phone
    }
}

// MARK: - Google Sign Up Response Model
struct GoogleSignUpResponse: Codable {
    let success: Bool
    let message: String?
    let data: GoogleSignUpData?
    let error: String?
    
    struct GoogleSignUpData: Codable {
        let id: String?
        let email: String?
        let name: String?
        let tenantId: String?
        let createdAt: String?
        let status: String?
    }
}
