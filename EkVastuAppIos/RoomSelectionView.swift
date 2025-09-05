import SwiftUI

struct RoomSelectionView: View {
    @ObservedObject var roomPhotoManager: RoomPhotoManager
    let roomIndex: Int
    @State private var showCameraView = false
    @State private var selectedPreviewImage: UIImage? = nil
    @State private var showingImagePopup = false
    @State private var isEditingRoomType = false
    @State private var tempRoomType: String = ""
    
    // Helper method to break up complex expressions
    private func getRoomType() -> String {
        guard roomIndex < roomPhotoManager.rooms.count else { return "" }
        return roomPhotoManager.rooms[roomIndex].roomType
    }
    
    // Helper method to check if room type can be edited
    private func canEditRoomType() -> Bool {
        guard roomIndex < roomPhotoManager.rooms.count else { return false }
        return roomPhotoManager.rooms[roomIndex].canEditRoomType
    }
    
    // Helper method to check if more photos can be added
    private func canAddMorePhotos() -> Bool {
        guard roomIndex < roomPhotoManager.rooms.count else { return false }
        return roomPhotoManager.rooms[roomIndex].canAddMorePhotos
    }
    
    // Helper method to get photos for this room
    private func getRoomPhotos() -> [RoomPhoto] {
        guard roomIndex < roomPhotoManager.rooms.count else { return [] }
        return roomPhotoManager.rooms[roomIndex].photos
    }
    
    // Helper method to check if analysis is started
    private func isAnalysisStarted() -> Bool {
        guard roomIndex < roomPhotoManager.rooms.count else { return false }
        return roomPhotoManager.rooms[roomIndex].isAnalysisStarted
    }
    
    // Helper method to check if analysis can be started
    private func canStartAnalysis() -> Bool {
        guard roomIndex < roomPhotoManager.rooms.count else { return false }
        return roomPhotoManager.rooms[roomIndex].canStartAnalysis
    }
    
    // Adapter binding to convert between RoomPhoto and UIImage arrays
    private var capturedImagesBinding: Binding<[UIImage]> {
        Binding<[UIImage]>(
            get: {
                // Convert RoomPhoto array to UIImage array
                guard roomIndex < roomPhotoManager.rooms.count else { return [] }
                return roomPhotoManager.rooms[roomIndex].photos.map { $0.image }
            },
            set: { newImages in
                // Convert UIImage array to RoomPhoto array
                guard roomIndex < roomPhotoManager.rooms.count else { return }
                
                let existingImages = Set(roomPhotoManager.rooms[roomIndex].photos.map { $0.image })
                
                // Find and add only the new images
                for image in newImages {
                    if !existingImages.contains(image) {
                        // Add as a new RoomPhoto
                        roomPhotoManager.addPhoto(to: roomIndex, photo: image)
                    }
                }
            }
        )
    }
    
    // Room type header view
    private var roomTypeHeaderView: some View {
        HStack {
            if canEditRoomType() {
                // Editable room type with dropdown
                roomTypeDropdownView
            } else {
                // Non-editable room type (photos exist)
                Text(getRoomType())
                    .font(.headline)
                    .foregroundColor(Color(hex: "#4A2511"))
            }
            
            Spacer()
            
            // Show analysis status if started
            if isAnalysisStarted() {
                Text("Analysis Started")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal)
    }
    
    // Room type dropdown view
    private var roomTypeDropdownView: some View {
        ZStack {
            // Dropdown button
            Button(action: {
                withAnimation {
                    isEditingRoomType.toggle()
                    if isEditingRoomType {
                        tempRoomType = getRoomType()
                    }
                }
            }) {
                HStack {
                    Text(getRoomType())
                        .font(.headline)
                        .foregroundColor(Color(hex: "#4A2511"))
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .rotationEffect(isEditingRoomType ? .degrees(180) : .degrees(0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Dropdown menu
            if isEditingRoomType {
                dropdownMenuView
            }
        }
    }
    
    // Dropdown menu view
    private var dropdownMenuView: some View {
        let currentRoomType = getRoomType()
        let availableTypes = roomPhotoManager.getAvailableRoomTypes()
        let allTypes = availableTypes + [currentRoomType]
        let sortedTypes = allTypes.sorted()
        
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sortedTypes, id: \.self) { roomType in
                Button(action: {
                    updateRoomType(to: roomType)
                }) {
                    Text(roomType)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                }
                Divider()
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .offset(y: 30)
        .zIndex(1)
    }
    
    // Update room type
    private func updateRoomType(to roomType: String) {
        if roomIndex < roomPhotoManager.rooms.count {
            var room = roomPhotoManager.rooms[roomIndex]
            room.roomType = roomType
            roomPhotoManager.rooms[roomIndex] = room
            roomPhotoManager.saveRooms()
        }
        isEditingRoomType = false
    }
    
    // Analysis button view
    private var analysisButtonView: some View {
        Group {
            if !isAnalysisStarted() || getRoomPhotos().isEmpty {
                Button(action: {
                    showCameraView = true
                    roomPhotoManager.startAnalysis(for: roomIndex)
                }) {
                    Text("Start Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(canStartAnalysis() ? Color(hex: "#4A2511") : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!canStartAnalysis())
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }
    
    // Photos section view
    private var photosSection: some View {
        Group {
            let photos = getRoomPhotos()
            if !photos.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Room Photos")
                        .font(.subheadline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Photo thumbnails
                            ForEach(0..<photos.count, id: \.self) { index in
                                photoThumbnailView(photo: photos[index], index: index)
                            }
                            
                            // More button
                            if canAddMorePhotos() {
                                addMorePhotosButton
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // Photo thumbnail view
    private func photoThumbnailView(photo: RoomPhoto, index: Int) -> some View {
        RoomPhotoThumbnailView(
            photo: photo,
            index: index,
            isUploading: roomPhotoManager.isUploading,
            onTap: {
                selectedPreviewImage = photo.image
                showingImagePopup = true
            },
            onDelete: {
                roomPhotoManager.deletePhoto(from: roomIndex, at: index)
            }
        )
    }
    
    // Add more photos button
    private var addMorePhotosButton: some View {
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
    
    // Image popup overlay
    private var imagePopupOverlay: some View {
        Group {
            if showingImagePopup, let image = selectedPreviewImage {
                ImagePopupOverlayView(
                    image: image,
                    entrancePhotos: [], // We're not using entrance photos here
                    isUploading: roomPhotoManager.isUploading,
                    onClose: {
                        showingImagePopup = false
                        selectedPreviewImage = nil
                    }
                )
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Room type header
            roomTypeHeaderView
            
            // Analysis button
            analysisButtonView
            
            // Photos section
            photosSection
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 5)
        .fullScreenCover(isPresented: $showCameraView) {
            CameraWithCompassView(capturedImages: capturedImagesBinding)
        }
        .overlay(imagePopupOverlay)
    }
}
