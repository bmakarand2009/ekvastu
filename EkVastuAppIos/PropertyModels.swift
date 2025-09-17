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
    let propertyType: String  // Changed from 'type' to match API response
    let street: String
    let city: String
    let state: String
    let zip: String
    let country: String
    let profileId: String?  // Changed from contactId to match API response
    let isActive: Bool?     // Added to match API response
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, street, city, state, zip, country
        case propertyType = "property_type"  // Maps to property_type in JSON
        case profileId = "profile_id"        // Maps to profile_id in JSON
        case isActive = "is_active"          // Maps to is_active in JSON
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Property Create Request Model
struct CreatePropertyRequest: Codable {
    let name: String
    let propertyType: String
    let street: String
    let city: String
    let state: String
    let zip: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case name, street, city, state, zip, country
        case propertyType = "property_type"
    }
}

// Property Update Request Model
struct UpdatePropertyRequest: Codable {
    let name: String?
    let propertyType: String?
    let street: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case name, street, city, state, zip, country
        case propertyType = "property_type"
    }
}
