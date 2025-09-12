import Foundation

struct RemedyResponse: Codable {
    let success: Bool
    let data: [Remedy]
    let count: Int
    let message: String
}

struct Remedy: Identifiable, Codable {
    let id: String
    let name: String
    let shortDesc: String
    let longDescription: String
    let instructions: [String]
    let image: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortDesc
        case longDescription
        case instructions
        case image
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
    // Temporarily removed filter types as requested
    // Will be reimplemented later
    case placeholder = "Remedies"
}
