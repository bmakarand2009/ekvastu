import SwiftUI

struct VastuGalleryView: View {
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var roomsWithPhotos: [RoomWithPhotos] = []
    
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
            .onAppear {
                loadRoomsWithPhotos()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - UI Components
    
    // Back button
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Vastu Gallery")
                    .font(.headline)
            }
            .foregroundColor(.black)
        }
    }
    
    // Expert consultation card
    private var consultationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Get Expert Consultation")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Connect with Jaya and get detailed analysis of your rooms and get your house Vastu approved")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToConsultTab"), object: nil)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        
                        Text("Consult")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color(hex: "#DD8E2E"))
                            .cornerRadius(8)
                    }
                     
                }
                .buttonStyle(PlainButtonStyle())
               
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
            ForEach(roomsWithPhotos) { room in
                roomSection(room: room)
            }
        }
    }
    
    // Individual room section
    private func roomSection(room: RoomWithPhotos) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Room card with thumbnail and delete button
            HStack {
                // Room thumbnail
                if let thumbnail = room.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
                
                // Room info
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.headline)
                    
                    if !room.photos.isEmpty && room.type.lowercased() == "entrance" {
                        NavigationLink(destination: GalleryRoomDetailView(room: room)) {
                            Text("View Analysis")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#DD8E2E"))
                        }
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // View (eye) icon - shows photos grid on tap (for all room types)
                NavigationLink(destination: GalleryRoomDetailView(room: room)) {
                    Image(systemName: "eye")
                        .foregroundColor(Color(hex: "#DD8E2E"))
                        .padding(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            .padding(.horizontal)
        }
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
                                            self.roomsWithPhotos = collectedRooms.sorted(by: { $0.name < $1.name })
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

// MARK: - Entrance Photos Grid View (80x80, with delete per photo)
struct EntrancePhotosGridView: View {
    let room: VastuGalleryView.RoomWithPhotos
    @State private var isLoading = true
    @State private var photos: [UIImage?] = []
    @State private var showDeleteConfirm = false
    @State private var deleteIndex: Int? = nil
    @State private var alertMessage: AlertMessage? = nil
    
    private let photoService = PhotoService.shared
    private let cloudinaryService = CloudinaryService()
    
    struct AlertMessage: Identifiable {
        let id = UUID()
        let text: String
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            VStack {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Text("Loading photos...").padding(.top, 8)
                    Spacer()
                } else if room.photos.isEmpty {
                    Spacer()
                    Text("No photos available").foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 12) {
                            ForEach(Array(room.photos.enumerated()), id: \.offset) { index, photoMeta in
                                VStack(spacing: 6) {
                                    if let image = photos[safe: index] ?? nil {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
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
        }
        .navigationBarTitle("View Analysis", displayMode: .inline)
        .onAppear { loadImages() }
        .alert(item: $alertMessage) { msg in
            Alert(title: Text("Info"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Are you sure you want to delete this photo?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) { showDeleteConfirm = false; deleteIndex = nil }
        }
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
    
    private func confirmDelete(index: Int) {
        deleteIndex = index
        showDeleteConfirm = true
    }
    
    private func performDelete() {
        guard let idx = deleteIndex else { return }
        showDeleteConfirm = false
        let photoMeta = room.photos[idx]
        Task {
            var cloudErr: String? = nil
            var apiErr: String? = nil
            // Delete from Cloudinary using the URL directly; proceed to API only if it succeeds
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
    
    // Extract Cloudinary asset_id (last filename without extension) from URL
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
