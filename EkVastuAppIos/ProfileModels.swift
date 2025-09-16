import Foundation

// MARK: - Profile Models

// Profile Response Model
struct ProfileResponse: Codable {
    let success: Bool
    let data: ProfileData?
    let error: String?
    let message: String?
}

struct ProfileData: Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let dob: String
    let placeOfBirth: String
    let timeOfBirth: String
    let contactId: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, dob
        case placeOfBirth = "place_of_birth"
        case timeOfBirth = "time_of_birth"
        case contactId = "contact_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Profile Create Request Model
struct CreateProfileRequest: Codable {
    let dob: String
    let placeOfBirth: String
    let timeOfBirth: String
    
    enum CodingKeys: String, CodingKey {
        case dob
        case placeOfBirth = "place_of_birth"
        case timeOfBirth = "time_of_birth"
    }
}

// Profile Update Request Model
struct UpdateProfileRequest: Codable {
    let dob: String
    let placeOfBirth: String
    let timeOfBirth: String
    
    enum CodingKeys: String, CodingKey {
        case dob
        case placeOfBirth = "place_of_birth"
        case timeOfBirth = "time_of_birth"
    }
}
