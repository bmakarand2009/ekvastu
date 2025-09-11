import Foundation

// MARK: - Question Models
struct RoomQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let type: String // "yes_no" | "multiple_choice"
    let options: [String]? // only for multiple_choice
}

struct RoomQuestionsResponse: Codable {
    let success: Bool
    let data: [RoomQuestion]
    let count: Int
}

// MARK: - Submit Answers
struct RoomAnswerItem: Codable {
    let question_id: String
    let answer: String
}

struct SubmitRoomAnswersRequest: Codable {
    let answers: [RoomAnswerItem]
}

struct SubmitRoomAnswersResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Vastu Score Models
struct RoomVastuScore: Codable {
    let room_id: String
    let score: Double
    let maxScore: Double
    
    // Optional fields that may not be present in all responses
    let room_name: String?
    let percentage: Double?
    let analysis: String?
    let calculated_at: String?
    
    // Computed property to calculate percentage if not provided
    var displayPercentage: Double {
        if let percentage = percentage {
            return percentage
        } else if maxScore > 0 {
            return (score / maxScore) * 100
        } else {
            return 0
        }
    }
}

struct RoomVastuScoreResponse: Codable {
    let success: Bool
    let data: RoomVastuScore
    let message: String?
}