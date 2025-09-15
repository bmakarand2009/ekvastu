import SwiftUI
import SafariServices

struct VastuGalleryView: View {
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var roomsWithPhotos: [RoomWithPhotos] = []
    @State private var showingSafari = false
    
    // Services
    private let roomService = RoomService.shared
    private let photoService = PhotoService.shared
    
    // Model for room with photos
    struct RoomWithPhotos: Identifiable {
        let id: String
        let name: String
        let type: String
        var photos: [PhotoData]
        var thumbnailImage: UIImage?
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    // Loading view
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading your Vastu Gallery...")
                            .font(.headline)
                            .padding(.top, 20)
                    }
                } else {
                    // Main content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Expert consultation card
                            consultationCard
                            
                            // Gallery title
                            Text("All your analyzed spaces are saved here.")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Room sections
                            if roomsWithPhotos.isEmpty {
                                emptyGalleryView
                            } else {
                                roomSections
                            }
                            
                            // Add Room button
                            addRoomButton
                                .padding(.vertical, 30)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: backButton)
            .toolbarBackground(Color(hex: "#FFF1E6"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadRoomsWithPhotos()
                
                // Set up notification observer for gallery refresh
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("RefreshGallery"),
                    object: nil,
                    queue: .main
                ) { _ in
                    self.loadRoomsWithPhotos()
                }
            }
            .onDisappear {
                // Remove notification observer when view disappears
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSNotification.Name("RefreshGallery"),
                    object: nil
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingSafari) {
                SafariView(url: URL(string: "https://bookme.name/JayaKaramchandani/discovery-call-home-vastu-visit-online-session")!)
            }
        }
    }
    
    // MARK: - UI Components
    
    // Back button
    private var backButton: some View {
        HStack(spacing: 10) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            Text("Vastu Gallery")
                .font(.headline)
                .foregroundColor(.black)
        }
    }
    
    // Expert consultation card
    private var consultationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Get Expert Consultation")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Connect with Jaya and get detailed analysis of your rooms and get your house Vastu approved")
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    // Open booking URL in SafariView
                    showingSafari = true
                }) {
                    HStack {
                        Text("Coffee With Jaya")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color(hex: "#DD8E2E"))
                            .cornerRadius(8)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // Empty gallery view
    private var emptyGalleryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No analyzed spaces yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add rooms and take photos to see them here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    // Room sections
    private var roomSections: some View {
        VStack(spacing: 20) {
            // Display entrance rooms first
            ForEach(roomsWithPhotos.filter { $0.type.lowercased() == "entrance" }) { room in
                roomSection(room: room)
            }
            
            // Then display all other rooms
            ForEach(roomsWithPhotos.filter { $0.type.lowercased() != "entrance" }) { room in
                roomSection(room: room)
            }
        }
    }
    
    // Individual room section
    private func roomSection(room: RoomWithPhotos) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Combined header and photos in a single card
            VStack(alignment: .leading, spacing: 0) {
                // Room header with name
                HStack(alignment: .center) { // Ensure center alignment
                    Text(room.name)
                        .font(.headline)
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    if room.type.lowercased() == "entrance" {
                        NavigationLink(destination: VastuAnalysisView(room: room)) {
                            Text("View Analysis")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#DD8E2E"))
                        }
                        .padding(.trailing, 20)
                        .buttonStyle(.plain)
                        
                    }
                }
                .padding(.vertical, 15) // Increase vertical padding
                
                // Photos grid - directly connected to the header
                if !room.photos.isEmpty {
                    // Load and display all photos
                    RoomPhotosGridView(room: room)
                        .padding(.horizontal, 20)
                        .padding(.top, 0) // Remove top padding
                        .padding(.bottom, 15) // Add bottom padding
                } else {
                    Text("No photos available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            .padding(.horizontal)
        }
        .padding(.bottom, 15)
    }
    
    // Add Room button
    private var addRoomButton: some View {
        
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Room")
                    .font(.headline)
            } .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(Color(hex: "#DD8E2E"))
                .cornerRadius(8)
             
        }
        .buttonStyle(PlainButtonStyle())
       
    }
    
    // MARK: - Data Loading
    
    // Load rooms with photos
    private func loadRoomsWithPhotos() {
        isLoading = true
        
        // Since there's no getAllRooms method, we'll fetch properties and then get rooms for each property
        let propertyService = PropertyService.shared
        
        // Get all properties first
        propertyService.getAllProperties { result in
            switch result {
            case .success(let response):
                if let properties = response.data, !properties.isEmpty {
                    // Process each property to get its rooms
                    let propertiesGroup = DispatchGroup()
                    var allRooms: [RoomData] = []
                    
                    for property in properties {
                        propertiesGroup.enter()
                        self.roomService.getRoomsInProperty(propertyId: property.id) { roomResult in
                            defer { propertiesGroup.leave() }
                            
                            if case .success(let roomResponse) = roomResult, let rooms = roomResponse.data {
                                allRooms.append(contentsOf: rooms)
                            }
                        }
                    }
                    
                    propertiesGroup.notify(queue: .main) {
                        // Process all rooms as if they came from a single API call
                        let rooms = allRooms
                        
                        // Process each room to get its photos
                        let roomsGroup = DispatchGroup()
                        var collectedRooms: [RoomWithPhotos] = []
                        
                        for room in rooms {
                            roomsGroup.enter()
                            
                            self.photoService.getPhotosInRoom(roomId: room.id) { photoResult in
                                defer { roomsGroup.leave() }
                                
                                switch photoResult {
                                case .success(let photoResponse):
                                    if let photos = photoResponse.data, !photos.isEmpty {
                                        // Create room with photos; append immediately so UI updates without waiting for thumbnail
                                        let roomWithPhotos = RoomWithPhotos(
                                            id: room.id,
                                            name: room.name,
                                            type: room.type,
                                            photos: photos,
                                            thumbnailImage: nil
                                        )
                                        
                                        DispatchQueue.main.async {
                                            collectedRooms.append(roomWithPhotos)
                                            // Sort rooms to ensure entrance rooms appear first, then alphabetically
                                            self.roomsWithPhotos = collectedRooms.sorted { (room1, room2) -> Bool in
                                                if room1.type.lowercased() == "entrance" && room2.type.lowercased() != "entrance" {
                                                    return true
                                                } else if room1.type.lowercased() != "entrance" && room2.type.lowercased() == "entrance" {
                                                    return false
                                                } else {
                                                    return room1.name < room2.name
                                                }
                                            }
                                        }
                                        
                                        // Load thumbnail using direct URL and update the room in-place when ready
                                        if let firstPhoto = photos.first {
                                            self.loadThumbnailImage(fromUrl: firstPhoto.uri) { image in
                                                DispatchQueue.main.async {
                                                    if let index = self.roomsWithPhotos.firstIndex(where: { $0.id == room.id }) {
                                                        self.roomsWithPhotos[index].thumbnailImage = image
                                                    }
                                                }
                                            }
                                        }
                                    }
                                case .failure(let error):
                                    print("Error loading photos for room \(room.id): \(error)")
                                }
                            }
                        }
                        
                        roomsGroup.notify(queue: .main) {
                            // All room photo metadata fetched (thumbnails may still be loading)
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to load rooms: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // Load thumbnail for a photo using its direct URL
    private func loadThumbnailImage(fromUrl urlString: String, completion: @escaping (UIImage?) -> Void) {
        Task {
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    completion(image)
                }
            } catch {
                print("Error loading thumbnail from URL: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - Room Photos Grid View
struct RoomPhotosGridView: View {
    let room: VastuGalleryView.RoomWithPhotos
    @State private var isLoading = true
    @State private var photos: [UIImage?] = []
    @State private var showDeleteConfirm = false
    @State private var deleteIndex: Int? = nil
    @State private var alertMessage: AlertMessage? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showFullScreenImage = false
    @State private var selectedPhotoIndex: Int? = nil
    
    private let photoService = PhotoService.shared
    private let cloudinaryService = CloudinaryService()
    
    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }
    
    var body: some View {
        VStack(spacing: 0) { // Remove default spacing
            if isLoading {
                ProgressView()
                    .padding()
                Text("Loading photos...")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if room.photos.isEmpty {
                Text("No photos available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Photos grid with 5px spacing - left aligned
                HStack(alignment: .center, spacing: 0) { // Change to center alignment
                    // Left-aligned grid
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(0..<(room.photos.count + 4) / 5, id: \.self) { row in
                            HStack(spacing: 5) {
                                ForEach(0..<min(5, room.photos.count - row * 5), id: \.self) { col in
                                    let index = row * 5 + col
                                    if let image = photos[safe: index] ?? nil {
                                        ZStack {
                                            NavigationLink(destination: 
                                                PhotoFullScreenView(image: image, photoMeta: room.photos[index], onDelete: { success in
                                                    if success {
                                                        // Remove the photo from the list
                                                        if index < photos.count {
                                                            photos.remove(at: index)
                                                            // Create a mutable copy of the photos array
                                                            var updatedPhotos = room.photos
                                                            updatedPhotos.remove(at: index)
                                                            // Update the room reference with the new photos
                                                            DispatchQueue.main.async {
                                                                // This is a workaround since we can't modify the original room
                                                                NotificationCenter.default.post(name: NSNotification.Name("RefreshGallery"), object: nil)
                                                            }
                                                        }
                                                    }
                                                })
                                            ) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .clipped()
                                                    .cornerRadius(4)
                                                    .buttonStyle(.plain)
                                            }
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(4)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 5)
            }
        }
        .onAppear { loadImages() }
        .alert(item: $alertMessage) { msg in
            Alert(title: Text("Info"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        // No longer using fullScreenCover as we're using NavigationLink instead
    }
    
    private func loadImages() {
        isLoading = true
        photos = Array(repeating: nil, count: room.photos.count)
        let group = DispatchGroup()
        for (index, p) in room.photos.enumerated() {
            group.enter()
            Task {
                if let url = URL(string: p.uri) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        let image = UIImage(data: data)
                        DispatchQueue.main.async { self.photos[index] = image; group.leave() }
                    } catch {
                        DispatchQueue.main.async { group.leave() }
                    }
                } else {
                    DispatchQueue.main.async { group.leave() }
                }
            }
        }
        group.notify(queue: .main) { isLoading = false }
    }
}

// MARK: - Photo Full Screen View with Delete
struct PhotoFullScreenView: View {
    let image: UIImage
    let photoMeta: PhotoData
    let onDelete: (Bool) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showDeleteConfirm = false
    @State private var alertMessage: AlertMessage? = nil
    
    private let photoService = PhotoService.shared
    private let cloudinaryService = CloudinaryService()
    
    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top bar with delete button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showDeleteConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Image with zoom capability
                GeometryReader { geometry in
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width)
                    }
                }
            }
        }
        .alert(item: $alertMessage) { msg in
            Alert(title: Text("Info"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Are you sure you want to delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { showDeleteConfirm = false }
        }
    }
    
    private func performDelete() {
        showDeleteConfirm = false
        Task {
            var cloudErr: String? = nil
            var apiErr: String? = nil
            var success = false
            
            // Delete from Cloudinary using the URL directly
            do {
                _ = try await cloudinaryService.deleteWithUrl(url: photoMeta.uri)
            } catch {
                cloudErr = error.localizedDescription
            }
            
            // If Cloudinary delete succeeded, delete from API
            if cloudErr == nil {
                do {
                    _ = try await photoService.deletePhoto(id: photoMeta.id)
                    success = true
                } catch {
                    apiErr = error.localizedDescription
                }
            }
            
            DispatchQueue.main.async {
                var parts: [String] = []
                if let c = cloudErr {
                    parts.append("Cloudinary delete failed: \(c)")
                    parts.append("API delete skipped due to Cloudinary failure")
                } else {
                    parts.append("Cloudinary delete success")
                    if let a = apiErr {
                        parts.append("API delete failed: \(a)")
                    } else {
                        parts.append("Photo deleted successfully")
                    }
                }
                
                self.alertMessage = AlertMessage(text: parts.joined(separator: "\n"))
                
                // If delete was successful, notify parent and dismiss after showing alert
                if success {
                    // Notify the parent about the deletion
                    onDelete(true)
                    
                    // Dismiss after a short delay to allow the user to see the success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Using Array extension from ExtensionUtility.swift

// MARK: - Room Detail View
struct GalleryRoomDetailView: View {
    let room: VastuGalleryView.RoomWithPhotos
    @State private var photos: [UIImage?] = []
    @State private var isLoading = true
    @State private var photoMetas: [PhotoData] = []
    @State private var showDeleteConfirm = false
    @State private var deleteIndex: Int? = nil
    @State private var alertMessage: AlertMessage? = nil
    @Environment(\.presentationMode) var presentationMode
    
    private let photoService = PhotoService.shared
    private let cloudinaryService = CloudinaryService()
    
    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            
            VStack {
                // Title shown only in navigation bar
                if isLoading {
                    // Loading view
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("Loading photos...")
                        .font(.headline)
                        .padding(.top, 20)
                    Spacer()
                } else if photos.isEmpty {
                    // No photos view
                    Spacer()
                    Text("No photos available")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // Photos grid 100x100 with delete button
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 100))], spacing: 12) {
                            ForEach(Array(photoMetas.enumerated()), id: \.offset) { index, _ in
                                VStack(spacing: 6) {
                                    if let image = photos.indices.contains(index) ? photos[index] : nil {
                                        NavigationLink(destination: FullScreenPhotoView(image: image)) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                        }
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    Button(action: { confirmDelete(index: index) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle(room.name, displayMode: .inline)
            .navigationBarBackButtonHidden(false)
        }
        .onAppear {
            photoMetas = room.photos
            loadPhotos()
        }
        .alert(item: $alertMessage) { msg in
            Alert(title: Text("Info"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Are you sure you want to delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { showDeleteConfirm = false; deleteIndex = nil }
        }
    }
    
    // Load all photos for the room
    private func loadPhotos() {
        isLoading = true
        photos = Array(repeating: nil, count: photoMetas.count)
        
        let group = DispatchGroup()
        
        for (index, photo) in photoMetas.enumerated() {
            group.enter()
            Task {
                guard let url = URL(string: photo.uri) else {
                    DispatchQueue.main.async { group.leave() }
                    return
                }
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        if index < self.photos.count {
                            self.photos[index] = image
                        }
                        group.leave()
                    }
                } catch {
                    print("Error loading photo at index \(index) from URL: \(error)")
                    DispatchQueue.main.async {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func confirmDelete(index: Int) {
        deleteIndex = index
        showDeleteConfirm = true
    }
    
    private func performDelete() {
        guard let idx = deleteIndex, idx < photoMetas.count else { return }
        showDeleteConfirm = false
        let photoMeta = photoMetas[idx]
        Task {
            var cloudErr: String? = nil
            var apiErr: String? = nil
            do {
                _ = try await cloudinaryService.deleteWithUrl(url: photoMeta.uri)
            } catch {
                cloudErr = error.localizedDescription
            }
            if cloudErr == nil {
                do {
                    _ = try await photoService.deletePhoto(id: photoMeta.id)
                } catch {
                    apiErr = error.localizedDescription
                }
            }
            DispatchQueue.main.async {
                if cloudErr == nil && apiErr == nil {
                    self.photoMetas.remove(at: idx)
                    if idx < self.photos.count { self.photos.remove(at: idx) }
                }
                var parts: [String] = ["URL: \(photoMeta.uri)"]
                if let c = cloudErr {
                    parts.append("Cloudinary delete failed: \(c)")
                    parts.append("API delete skipped due to Cloudinary failure")
                } else {
                    parts.append("Cloudinary delete success")
                    if let a = apiErr {
                        parts.append("API delete failed: \(a)")
                    } else {
                        parts.append("API delete success")
                    }
                }
                self.alertMessage = AlertMessage(text: parts.joined(separator: "\n"))
            }
        }
    }
    
    private func cloudinaryAssetId(from uri: String) -> String? {
        guard let url = URL(string: uri) else { return nil }
        let path = (url.path.removingPercentEncoding ?? url.path)
        if let uploadRange = path.range(of: "/upload/") {
            let after = String(path[uploadRange.upperBound...])
            let segments = after.split(separator: "/").map(String.init)
            if let lastSeg = segments.last {
                let base = lastSeg.split(separator: ".").first.map(String.init) ?? lastSeg
                return base.isEmpty ? nil : base
            }
            return nil
        } else {
            let last = url.deletingPathExtension().lastPathComponent
            return last.isEmpty ? nil : last
        }
    }
}
