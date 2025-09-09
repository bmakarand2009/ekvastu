import Foundation

// MARK: - Room Models

// Room Response Model
struct RoomResponse: Codable {
    let success: Bool
    let data: RoomData?
    let error: String?
    let message: String?
}

struct RoomsResponse: Codable {
    let success: Bool
    let data: [RoomData]?
    let error: String?
    let message: String?
}

struct RoomData: Codable {
    let id: String
    let name: String
    let type: String
    let propertyId: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, type
        case propertyId = "property_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Room Create Request Model
struct CreateRoomRequest: Codable {
    let name: String
    let type: String
}

// Room Update Request Model
struct UpdateRoomRequest: Codable {
    let name: String?
    let type: String?
}
