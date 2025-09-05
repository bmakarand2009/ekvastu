import SwiftUI

// Thumbnail view component for room photos
struct RoomPhotoThumbnailView: View {
    let photo: RoomPhoto
    let index: Int
    let isUploading: Bool
    var onTap: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 5) {
            // Image thumbnail with tap action
            Button(action: onTap) {
                ZStack {
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .clipped()
                    
                    // Show upload indicator if no assetId yet
                    if photo.assetId == nil && isUploading {
                        Color.black.opacity(0.5)
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    
                    // Show cloud icon if successfully uploaded
                    if photo.assetId != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.green)
                                    .padding(5)
                                    .background(Circle().fill(Color.white.opacity(0.8)))
                            }
                        }
                        .padding(5)
                    }
                }
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.8)))
                    .shadow(radius: 2)
            }
            .offset(y: -15) // Move up to overlap with the image
            .disabled(photo.assetId == nil && isUploading) // Disable delete during upload
            .opacity(photo.assetId == nil && isUploading ? 0.5 : 1) // Dim during upload
        }
        .frame(width: 100, height: 120) // Adjust height to accommodate delete button
    }
}
