import Foundation

// MARK: - Sign Up Request Model
struct SignUpRequest: Codable {
    let name: String
    let lastName: String?
    let email: String
    let phone: String?
    let tenantId: String
    let referral: String?
    let interestedIn: String?
    let leadSource: String?
    let description: String?
    let line1: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let timezone: String?
    
    // Initialize with mandatory fields and optional parameters
    init(
        name: String,
        email: String,
        tenantId: String,
        lastName: String? = nil,
        phone: String? = nil,
        referral: String? = nil,
        interestedIn: String? = nil,
        leadSource: String? = nil,
        description: String? = nil,
        line1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        timezone: String? = nil
    ) {
        self.name = name
        self.email = email
        self.tenantId = tenantId
        self.lastName = lastName
        self.phone = phone
        self.referral = referral
        self.interestedIn = interestedIn
        self.leadSource = leadSource
        self.description = description
        self.line1 = line1
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
        self.timezone = timezone
    }
}

// MARK: - Sign Up Response Model
struct SignUpResponse: Codable {
    let success: Bool
    let message: String?
    let data: SignUpData?
    let error: String?
    
    struct SignUpData: Codable {
        let id: String?
        let email: String?
        let name: String?
        let tenantId: String?
        let createdAt: String?
        let status: String?
    }
}
