import SwiftUI
import Foundation

// Structure to store both image and its Cloudinary metadata
struct RoomPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    var assetId: String?
    var publicId: String?
    var secureUrl: String?
}

// Structure to represent a room with its type and photos
struct Room: Identifiable {
    let id = UUID()
    var roomType: String
    var photos: [RoomPhoto] = []
    var isAnalysisStarted = false
    
    // Maximum number of photos allowed per room
    static let maxPhotos = 3
    
    // Check if more photos can be added
    var canAddMorePhotos: Bool {
        return photos.count < Room.maxPhotos
    }
    
    // Check if analysis can be started (room type selected and no photos yet)
    var canStartAnalysis: Bool {
        return !roomType.isEmpty && photos.isEmpty
    }
    
    // Check if room type can be edited (no photos captured yet)
    var canEditRoomType: Bool {
        return photos.isEmpty
    }
}

@MainActor
class RoomPhotoManager: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var isUploading = false
    
    // Cloudinary service
    private let cloudinaryService: CloudinaryService
    
    // Available room types
    let roomTypes = ["Living Room", "Bed Room", "Office Room", "Kitchen", "Hall", "Balcony", "Study Room", "Bath Room", "Other"]
    
    // Initialize with CloudinaryService
    init() {
        self.cloudinaryService = CloudinaryService()
        loadRooms()
    }
    
    // Add a new room
    func addRoom(roomType: String) {
        let newRoom = Room(roomType: roomType)
        rooms.append(newRoom)
        saveRooms()
    }
    
    // Add a photo to a specific room
    func addPhoto(to roomIndex: Int, photo: UIImage) {
        guard roomIndex >= 0 && roomIndex < rooms.count else { return }
        guard rooms[roomIndex].canAddMorePhotos else { return }
        
        // Create a temporary photo entry while uploading
        let tempPhoto = RoomPhoto(image: photo)
        rooms[roomIndex].photos.append(tempPhoto)
        
        // Upload to Cloudinary
        uploadPhotoToCloudinary(photo: photo, roomIndex: roomIndex, photoIndex: rooms[roomIndex].photos.count - 1)
    }
    
    // Upload photo to Cloudinary
    private func uploadPhotoToCloudinary(photo: UIImage, roomIndex: Int, photoIndex: Int) {
        isUploading = true
        
        Task { @MainActor in
            do {
                // Since we're already in a MainActor context, we can directly call CloudinaryService
                let response = try await cloudinaryService.uploadImage(photo)
                
                // Update the photo with Cloudinary metadata
                if roomIndex < rooms.count && photoIndex < rooms[roomIndex].photos.count {
                    var updatedPhoto = rooms[roomIndex].photos[photoIndex]
                    updatedPhoto.assetId = response.assetId
                    updatedPhoto.publicId = response.publicId
                    updatedPhoto.secureUrl = response.secureUrl
                    rooms[roomIndex].photos[photoIndex] = updatedPhoto
                    
                    // Save the updated rooms
                    saveRooms()
                    isUploading = false
                }
            } catch {
                print("Error uploading to Cloudinary: \(error.localizedDescription)")
                isUploading = false
            }
        }
    }
    
    // Delete a photo from a specific room
    func deletePhoto(from roomIndex: Int, at photoIndex: Int) {
        guard roomIndex >= 0 && roomIndex < rooms.count else { return }
        guard photoIndex >= 0 && photoIndex < rooms[roomIndex].photos.count else { return }
        
        // Delete from Cloudinary if assetId exists
        if let assetId = rooms[roomIndex].photos[photoIndex].assetId {
            deleteFromCloudinary(assetId: assetId)
        }
        
        rooms[roomIndex].photos.remove(at: photoIndex)
        
        // Reset analysis state if all photos are deleted
        if rooms[roomIndex].photos.isEmpty {
            rooms[roomIndex].isAnalysisStarted = false
        }
        
        saveRooms()
    }
    
    // Delete photo from Cloudinary
    private func deleteFromCloudinary(assetId: String) {
        Task { @MainActor in
            do {
                let response = try await cloudinaryService.deleteImage(assetId: assetId)
                print("Successfully deleted image from Cloudinary: \(assetId)")
            } catch {
                print("Error deleting from Cloudinary: \(error.localizedDescription)")
            }
        }
    }
    
    // Mark a room as analysis started
    func startAnalysis(for roomIndex: Int) {
        guard roomIndex >= 0 && roomIndex < rooms.count else { return }
        rooms[roomIndex].isAnalysisStarted = true
        saveRooms()
    }
    
    // Get available room types (excluding already selected ones)
    func getAvailableRoomTypes() -> [String] {
        let selectedRoomTypes = Set(rooms.map { $0.roomType })
        return roomTypes.filter { !selectedRoomTypes.contains($0) }
    }
    
    // Check if more rooms can be added
    var canAddMoreRooms: Bool {
        return rooms.count < roomTypes.count
    }
    
    // Save rooms to UserDefaults
    func saveRooms() {
        // Create an array of dictionaries to store room data
        let roomsData = rooms.map { room -> [String: Any] in
            var roomDict: [String: Any] = [:]
            roomDict["roomType"] = room.roomType
            roomDict["isAnalysisStarted"] = room.isAnalysisStarted
            
            // Convert photos to dictionaries
            let photosData = room.photos.map { photo -> [String: Any] in
                var photoDict: [String: Any] = [:]
                if let imageData = photo.image.jpegData(compressionQuality: 0.7) {
                    photoDict["imageData"] = imageData
                }
                photoDict["assetId"] = photo.assetId
                photoDict["publicId"] = photo.publicId
                photoDict["secureUrl"] = photo.secureUrl
                return photoDict
            }
            
            roomDict["photos"] = photosData
            return roomDict
        }
        
        UserDefaults.standard.set(roomsData, forKey: "rooms")
    }
    
    // Load rooms from UserDefaults
    func loadRooms() {
        guard let roomsData = UserDefaults.standard.array(forKey: "rooms") as? [[String: Any]] else {
            return
        }
        
        rooms = roomsData.compactMap { roomDict -> Room? in
            guard let roomType = roomDict["roomType"] as? String else { return nil }
            
            var room = Room(roomType: roomType)
            room.isAnalysisStarted = roomDict["isAnalysisStarted"] as? Bool ?? false
            
            // Load photos
            if let photosData = roomDict["photos"] as? [[String: Any]] {
                room.photos = photosData.compactMap { photoDict -> RoomPhoto? in
                    guard let imageData = photoDict["imageData"] as? Data,
                          let image = UIImage(data: imageData) else {
                        return nil
                    }
                    
                    var photo = RoomPhoto(image: image)
                    photo.assetId = photoDict["assetId"] as? String
                    photo.publicId = photoDict["publicId"] as? String
                    photo.secureUrl = photoDict["secureUrl"] as? String
                    return photo
                }
            }
            
            return room
        }
    }
    
    // Clear all rooms and photos
    func clearAllRooms() {
        // Delete all photos from Cloudinary
        for room in rooms {
            for photo in room.photos {
                if let assetId = photo.assetId {
                    deleteFromCloudinary(assetId: assetId)
                }
            }
        }
        
        rooms.removeAll()
        UserDefaults.standard.removeObject(forKey: "rooms")
    }
}
