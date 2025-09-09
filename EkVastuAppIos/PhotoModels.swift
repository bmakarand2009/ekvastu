import Foundation

// MARK: - Photo Models

// Photo Response Model
struct PhotoResponse: Codable {
    let success: Bool
    let data: PhotoData?
    let error: String?
    let message: String?
}

struct PhotosResponse: Codable {
    let success: Bool
    let data: [PhotoData]?
    let error: String?
    let message: String?
}

struct PhotoData: Codable {
    let id: String
    let roomId: String
    let photoUrl: String
    let cloudName: String
    let folderName: String
    let uri: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case photoUrl = "photo_url"
        case cloudName = "cloud_name"
        case folderName = "folder_name"
        case uri
        case createdAt = "created_at"
    }
}

// Photo Create Request Model (for URL method)
struct CreatePhotoRequest: Codable {
    let cloudName: String
    let uri: String
    
    enum CodingKeys: String, CodingKey {
        case cloudName = "cloud_name"
        case uri
    }
}

// Delete Response Model
struct DeleteResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
