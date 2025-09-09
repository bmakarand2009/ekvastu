import Foundation

// MARK: - Property Models

// Property Response Model
struct PropertyResponse: Codable {
    let success: Bool
    let data: PropertyData?
    let error: String?
    let message: String?
}

struct PropertiesResponse: Codable {
    let success: Bool
    let data: [PropertyData]?
    let error: String?
    let message: String?
}

struct PropertyData: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let street: String
    let city: String
    let state: String
    let zip: String
    let country: String
    let contactId: String?  // Made optional since API doesn't always return it
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, street, city, state, zip, country
        case contactId = "contact_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Property Create Request Model
struct CreatePropertyRequest: Codable {
    let name: String
    let type: String
    let street: String
    let city: String
    let state: String
    let zip: String
    let country: String
}

// Property Update Request Model
struct UpdatePropertyRequest: Codable {
    let name: String?
    let type: String?
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
}
