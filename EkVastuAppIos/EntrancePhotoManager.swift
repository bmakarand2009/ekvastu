import SwiftUI
import Foundation

// Structure to store both image and its Cloudinary metadata
struct EntrancePhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    var assetId: String?
    var publicId: String?
    var secureUrl: String?
}

@MainActor
class EntrancePhotoManager: ObservableObject {
    @Published var entrancePhotos: [EntrancePhoto] = []
    @Published var isUploading = false
    
    // Cloudinary service
    private let cloudinaryService: CloudinaryService
    
    // Maximum number of photos allowed
    let maxPhotos = 3
    
    // Add a new photo to the collection and upload to Cloudinary
    func addPhoto(_ photo: UIImage) {
        if entrancePhotos.count < maxPhotos {
            // Create a temporary photo entry while uploading
            let tempPhoto = EntrancePhoto(image: photo)
            entrancePhotos.append(tempPhoto)
            
            // Upload to Cloudinary
            uploadPhotoToCloudinary(photo: photo, index: entrancePhotos.count - 1)
        }
    }
    
    // Upload photo to Cloudinary
    private func uploadPhotoToCloudinary(photo: UIImage, index: Int) {
        isUploading = true
        
        Task { @MainActor in
            do {
                // Since we're already in a MainActor context, we can directly call CloudinaryService
                let response = try await cloudinaryService.uploadImage(photo)
                
                // Update the photo with Cloudinary metadata
                if index < entrancePhotos.count {
                    var updatedPhoto = entrancePhotos[index]
                    updatedPhoto.assetId = response.assetId
                    updatedPhoto.publicId = response.publicId
                    updatedPhoto.secureUrl = response.secureUrl
                    entrancePhotos[index] = updatedPhoto
                    
                    // Save the updated photos
                    savePhotos()
                    isUploading = false
                }
            } catch {
                print("Error uploading to Cloudinary: \(error.localizedDescription)")
                isUploading = false
            }
        }
    }
    
    // Check if more photos can be added
    var canAddMorePhotos: Bool {
        return entrancePhotos.count < maxPhotos
    }
    
    // Save photos to UserDefaults
    private func savePhotos() {
        // Create an array of dictionaries to store both image data and Cloudinary metadata
        let photoDataArray = entrancePhotos.map { photo -> [String: Any] in
            var photoDict: [String: Any] = [:]            
            if let imageData = photo.image.jpegData(compressionQuality: 0.7) {
                photoDict["imageData"] = imageData
            }
            photoDict["assetId"] = photo.assetId
            photoDict["publicId"] = photo.publicId
            photoDict["secureUrl"] = photo.secureUrl
            return photoDict
        }
        
        UserDefaults.standard.set(photoDataArray, forKey: "entrancePhotos")
    }
    
    // Load photos from UserDefaults
    func loadPhotos() {
        guard let photoDataArray = UserDefaults.standard.array(forKey: "entrancePhotos") as? [[String: Any]] else {
            return
        }
        
        entrancePhotos = photoDataArray.compactMap { photoDict -> EntrancePhoto? in
            guard let imageData = photoDict["imageData"] as? Data,
                  let image = UIImage(data: imageData) else {
                return nil
            }
            
            var photo = EntrancePhoto(image: image)
            photo.assetId = photoDict["assetId"] as? String
            photo.publicId = photoDict["publicId"] as? String
            photo.secureUrl = photoDict["secureUrl"] as? String
            return photo
        }
    }
    
    // Clear all photos
    func clearPhotos() {
        // Delete all photos from Cloudinary first
        for photo in entrancePhotos {
            if let assetId = photo.assetId {
                deleteFromCloudinary(assetId: assetId)
            }
        }
        
        entrancePhotos.removeAll()
        UserDefaults.standard.removeObject(forKey: "entrancePhotos")
    }
    
    // Delete a specific photo by index
    func deletePhoto(at index: Int) {
        guard index >= 0 && index < entrancePhotos.count else { return }
        
        // Delete from Cloudinary if assetId exists
        if let assetId = entrancePhotos[index].assetId {
            deleteFromCloudinary(assetId: assetId)
        }
        
        entrancePhotos.remove(at: index)
        savePhotos()
    }
    
    // Delete photo from Cloudinary
    private func deleteFromCloudinary(assetId: String) {
        Task { @MainActor in
            do {
                _ = try await cloudinaryService.deleteImage(assetId: assetId)
                print("Successfully deleted image from Cloudinary: \(assetId)")
            } catch {
                print("Error deleting from Cloudinary: \(error.localizedDescription)")
            }
        }
    }
    
    init() {
        // Initialize CloudinaryService on the main actor
        self.cloudinaryService = CloudinaryService()
        loadPhotos()
    }
}
