import SwiftUI
import AVFoundation

struct HomeAnalyzeView: View {
    @State private var selectedRoomType: String = "Select room type"
    @State private var isRoomTypeSelected: Bool = false
    @State private var isDropdownOpen = false
    @State private var showCameraView = false
    @State private var showPhotoPreview = false
    @State private var selectedPreviewImage: UIImage? = nil
    @State private var showingImagePopup = false
    @StateObject private var photoManager = EntrancePhotoManager()
    
    // Room types available for selection
    private let roomTypes = ["Living room", "Bedroom", "Office Room", "Kitchen", "Hall", "Balcony", "Study Room", "Bath Room"]
    
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
                            .background(Color(hex: "#4A2511"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .fullScreenCover(isPresented: $showCameraView) {
                        CameraWithCompassView(capturedImages: $photoManager.entrancePhotos)
                    }
                    
                    // Display captured photos
                    if !photoManager.entrancePhotos.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Entrance Photos")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 15)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<photoManager.entrancePhotos.count, id: \.self) { index in
                                        VStack(spacing: 5) {
                                            // Image thumbnail with tap action
                                            Button(action: {
                                                selectedPreviewImage = photoManager.entrancePhotos[index]
                                                showingImagePopup = true
                                            }) {
                                                Image(uiImage: photoManager.entrancePhotos[index])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                    .clipped()
                                            }
                                            
                                            // Delete button
                                            Button(action: {
                                                photoManager.deletePhoto(at: index)
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.red)
                                                    .frame(width: 30, height: 30)
                                                    .background(Circle().fill(Color.white.opacity(0.8)))
                                                    .shadow(radius: 2)
                                            }
                                            .offset(y: -15) // Move up to overlap with the image
                                        }
                                        .frame(width: 100, height: 120) // Adjust height to accommodate delete button
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
                                        } .padding(.top, -30)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Room selection dropdown and Start Analysis button
                    HStack(spacing: 10) {
                        // Custom dropdown button
                        ZStack {
                            Button(action: {
                                withAnimation {
                                    isDropdownOpen.toggle()
                                }
                            }) {
                                HStack {
                                    Text(selectedRoomType)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                        .rotationEffect(isDropdownOpen ? .degrees(180) : .degrees(0))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Dropdown menu
                            if isDropdownOpen {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(roomTypes, id: \.self) { roomType in
                                        Button(action: {
                                            selectedRoomType = roomType
                                            isDropdownOpen = false
                                            isRoomTypeSelected = true
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
                                .offset(y: 50)
                                .zIndex(1)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.55)
                        
                        // Start Analysis button
                        Button(action: {
                            // Action for starting analysis
                        }) {
                            Text("Start Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isRoomTypeSelected ? Color(hex: "#4A2511") : Color.gray)
                                .cornerRadius(8)
                        }
                        .disabled(!isRoomTypeSelected)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .onAppear {
            photoManager.loadPhotos()
        }
        .fullScreenCover(isPresented: $showPhotoPreview, onDismiss: nil) {
            if let image = selectedPreviewImage {
                PhotoPreviewView(image: image)
            }
        }
        .overlay(
            Group {
                if showingImagePopup, let image = selectedPreviewImage {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.9)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showingImagePopup = false
                                selectedPreviewImage = nil
                            }
                        
                        VStack {
                            // Close button
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingImagePopup = false
                                    selectedPreviewImage = nil
                                }) {
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
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
                            
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showingImagePopup)
                }
            }
        )
    }
}
