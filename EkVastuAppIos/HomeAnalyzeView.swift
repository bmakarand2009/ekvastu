import SwiftUI
import AVFoundation

// Thumbnail view component for entrance photos
struct EntrancePhotoThumbnailView: View {
    let photo: EntrancePhoto
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

// Image popup overlay for full-screen preview
struct ImagePopupOverlayView: View {
    let image: UIImage
    let entrancePhotos: [EntrancePhoto]
    let isUploading: Bool
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture(perform: onClose)
            
            VStack(spacing: 10) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Full image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.95)
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                
                // Find the corresponding photo to display metadata
                let selectedPhoto = entrancePhotos.first(where: { $0.image == image })
                
                // Cloudinary metadata
                Group {
                    if let photo = selectedPhoto, let assetId = photo.assetId {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.green)
                                Text("Uploaded to Cloudinary")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            Text("Asset ID: \(assetId)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    } else if isUploading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Uploading to Cloudinary...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    } else {
                        Text("Not uploaded to Cloudinary")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

// This component is no longer needed as we're using RoomSelectionView instead

struct HomeAnalyzeView: View {
    @State private var showCameraView = false
    @State private var showPhotoPreview = false
    @State private var selectedPreviewImage: UIImage? = nil
    @State private var showingImagePopup = false
    @StateObject private var photoManager = EntrancePhotoManager()
    @StateObject private var roomPhotoManager = RoomPhotoManager()
    
    // Adapter binding to convert between EntrancePhoto and UIImage arrays
    private var capturedImagesBinding: Binding<[UIImage]> {
        Binding<[UIImage]>(
            get: {
                // Convert EntrancePhoto array to UIImage array
                return self.photoManager.entrancePhotos.map { $0.image }
            },
            set: { newImages in
                // Convert UIImage array to EntrancePhoto array
                // This will be called when CameraWithCompassView adds new images
                let existingImages = Set(photoManager.entrancePhotos.map { $0.image })
                
                // Find and add only the new images
                for image in newImages {
                    if !existingImages.contains(image) {
                        // Add as a new EntrancePhoto
                        photoManager.addPhoto(image)
                    }
                }
            }
        )
    }
    
    // This property is no longer needed as we're using photoManager.entrancePhotos.isEmpty directly
    
    // ...
    // Extract photo thumbnails section to reduce complexity
    private var photoThumbnailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Entrance Photos")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 15)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(photoManager.entrancePhotos.indices, id: \.self) { index in
                        EntrancePhotoThumbnailView(
                            photo: photoManager.entrancePhotos[index],
                            index: index,
                            isUploading: photoManager.isUploading,
                            onTap: {
                                selectedPreviewImage = photoManager.entrancePhotos[index].image
                                showingImagePopup = true
                            },
                            onDelete: {
                                photoManager.deletePhoto(at: index)
                            }
                        )
                    }
                    
                    // More button
                    if photoManager.canAddMorePhotos {
                        Button(action: {
                            showCameraView = true
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                Text("More")
                                    .font(.caption)
                            }
                            .foregroundColor(Color(hex: "#4A2511"))
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .padding(.top, -30)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Extract room selection section to reduce complexity
    private var roomSelectionSection: some View {
        VStack(spacing: 15) {
            Text("Room Analysis")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 20)
            
            // Display each room section
            ForEach(0..<roomPhotoManager.rooms.count, id: \.self) { index in
                RoomSelectionView(roomPhotoManager: roomPhotoManager, roomIndex: index)
            }
            
            // Add Another Room button
            if roomPhotoManager.canAddMoreRooms {
                AddRoomView(roomPhotoManager: roomPhotoManager)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                // Logo at the top
                Image("headerimage")
                    .frame(width: 78)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text("Analyze your space")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal)
                
                VStack(alignment: .center, spacing: 0) {
                    // Property image
                    Image("property")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Description text
                    Text("Start your Vastu journey by scanning the entrance of your home to check its alignment, then select a room type to analyze and receive personalized insights.")
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    // Analyze Entrance button
                    Button(action: {
                        showCameraView = true
                    }) {
                        Text("Analyze Entrance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(photoManager.entrancePhotos.isEmpty ? Color(hex: "#4A2511") : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!photoManager.entrancePhotos.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .fullScreenCover(isPresented: $showCameraView) {
                        CameraWithCompassView(capturedImages: capturedImagesBinding)
                    }
                    
                    // Display captured photos using extracted component
                    if !photoManager.entrancePhotos.isEmpty {
                        photoThumbnailsSection
                    }
                    
                    // Room sections
                    VStack(spacing: 15) {
                        Text("Room Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Display each room section
                        ForEach(0..<roomPhotoManager.rooms.count, id: \.self) { index in
                            RoomSelectionView(roomPhotoManager: roomPhotoManager, roomIndex: index)
                        }
                        
                        // Add Another Room button
                        if roomPhotoManager.canAddMoreRooms {
                            AddRoomView(roomPhotoManager: roomPhotoManager)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear {
            photoManager.loadPhotos()
            roomPhotoManager.loadRooms()
        }
        .fullScreenCover(isPresented: $showPhotoPreview, onDismiss: nil) {
            if let image = selectedPreviewImage {
                PhotoPreviewView(image: image)
            }
        }
        .overlay(
            Group {
                if showingImagePopup, let image = selectedPreviewImage {
                    // Use the extracted ImagePopupOverlayView component
                    ImagePopupOverlayView(
                        image: image,
                        entrancePhotos: photoManager.entrancePhotos,
                        isUploading: photoManager.isUploading,
                        onClose: {
                            showingImagePopup = false
                            selectedPreviewImage = nil
                        }
                    )
                }
            }
        )
    }
}
