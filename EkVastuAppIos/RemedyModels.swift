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

// RemedyStep removed - unused

// RemedyFilterType removed - unused
