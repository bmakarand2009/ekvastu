import SwiftUI
import Foundation

class EntrancePhotoManager: ObservableObject {
    @Published var entrancePhotos: [UIImage] = []
    
    // Maximum number of photos allowed
    let maxPhotos = 3
    
    // Add a new photo to the collection
    func addPhoto(_ photo: UIImage) {
        if entrancePhotos.count < maxPhotos {
            entrancePhotos.append(photo)
            savePhotos()
        }
    }
    
    // Check if more photos can be added
    var canAddMorePhotos: Bool {
        return entrancePhotos.count < maxPhotos
    }
    
    // Save photos to UserDefaults
    private func savePhotos() {
        let imageData = entrancePhotos.map { image -> Data? in
            return image.jpegData(compressionQuality: 0.7)
        }
        
        // Filter out any nil values
        let validImageData = imageData.compactMap { $0 }
        
        UserDefaults.standard.set(validImageData, forKey: "entrancePhotos")
    }
    
    // Load photos from UserDefaults
    func loadPhotos() {
        guard let imageDataArray = UserDefaults.standard.array(forKey: "entrancePhotos") as? [Data] else {
            return
        }
        
        entrancePhotos = imageDataArray.compactMap { data -> UIImage? in
            return UIImage(data: data)
        }
    }
    
    // Clear all photos
    func clearPhotos() {
        entrancePhotos.removeAll()
        UserDefaults.standard.removeObject(forKey: "entrancePhotos")
    }
    
    // Delete a specific photo by index
    func deletePhoto(at index: Int) {
        guard index >= 0 && index < entrancePhotos.count else { return }
        entrancePhotos.remove(at: index)
        savePhotos()
    }
    
    init() {
        loadPhotos()
    }
}
