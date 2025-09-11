import Foundation

struct Remedy: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let roomType: String?
    let issueType: String?
    let steps: [RemedyStep]
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case imageUrl
        case roomType
        case issueType
        case steps
    }
}

struct RemedyStep: Identifiable, Codable {
    let id: String
    let stepNumber: Int
    let description: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case stepNumber
        case description
        case imageUrl
    }
}

enum RemedyFilterType: String, CaseIterable {
    case all = "All"
    case room = "Room"
    case issue = "Issue"
}
