import Foundation

// MARK: - Room Models

// Question Model
struct QuestionData: Codable, Identifiable {
    let id: String
    let roomType: String
    let questionText: String
    let questionOrder: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomType = "room_type"
        case questionText = "question_text"
        case questionOrder = "question_order"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Answer Model
struct AnswerData: Codable, Identifiable {
    let id: String
    let roomId: String
    let questionId: String
    let answerText: String
    let answerValue: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case questionId = "question_id"
        case answerText = "answer_text"
        case answerValue = "answer_value"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

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
    let floorLevel: Int?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let questions: [QuestionData]
    let answers: [AnswerData]
    
    enum CodingKeys: String, CodingKey {
        case id, name, questions, answers
        case type = "room_type"
        case propertyId = "property_id"
        case floorLevel = "floor_level"
        case isActive = "is_active"
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
