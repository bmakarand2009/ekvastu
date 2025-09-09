import SwiftUI

struct HomeAnalyzeView: View {
    @State private var showCameraView = false
    @State private var showEntranceCameraView = false
    @State private var showVastuGallery = false

    @State private var backendRooms: [RoomData] = []
    @State private var selectedRoom: String? = nil // Now stores room ID instead of room name
    @State private var showAddRoomField = false
    @State private var newRoomName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoadingRooms = false
    @State private var properties: [PropertyData] = []
    @State private var selectedPropertyForRoom: PropertyData? = nil
    @State private var showPropertySelection = false
    @State private var entranceObject: RoomData? = nil // Stores the entrance room data
    
    // Photo management
    @State private var entrancePhotos: [CapturedPhoto] = []
    @State private var roomPhotos: [CapturedPhoto] = []
    @State private var maxPhotosForCamera = 4
    @State private var existingPhotosForCamera = 0
    
    // Property type passed from previous screen
    let selectedPropertyType: String
    // Property ID passed from previous screen
    let propertyId: String
    
    // Services
    private let roomService = RoomService.shared
    private let propertyService = PropertyService.shared
    private let photoService = PhotoService.shared
    
    // Available property types
    private let propertyTypes = ["residential", "commercial", "work", "other"]
    
    // Properties filtered by selected type
    private var propertiesForSelectedType: [PropertyData] {
        return properties.filter { $0.type.lowercased() == selectedPropertyType.lowercased() }
    }
    
    // Rooms filtered by selected property type
    private var roomsForSelectedType: [RoomData] {
        let propertyIds = propertiesForSelectedType.map { $0.id }
        return backendRooms.filter { propertyIds.contains($0.propertyId) }
    }
    
    // All rooms for the current property (excluding entrance rooms)
    private var allRooms: [RoomData] {
        // Filter rooms directly by the current property ID and exclude entrance rooms
        return backendRooms.filter { $0.propertyId == propertyId && $0.type.lowercased() != "entrance" }
    }
    
    // Room names for the current property (for checking duplicates)
    private var allRoomNames: [String] {
        return allRooms.map { $0.name }
    }
    
    // Room creation with backend API
    private func addRoom() {
        let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a room name"
            showAlert = true
            return
        }
        
        guard !allRoomNames.contains(trimmedName) else {
            alertMessage = "Room '\(trimmedName)' already exists"
            showAlert = true
            return
        }
        
        // Use the property ID that was passed to this view
        // No need to check for properties of selected type since we already have a valid property ID
        
        // Show loading state
        isLoadingRooms = true
        
        // Create room in backend
        roomService.createRoom(
            propertyId: propertyId,
            name: trimmedName,
            type: "bedroom" // Default type
        ) { result in
            DispatchQueue.main.async {
                self.isLoadingRooms = false
                
                switch result {
                case .success(let response):
                    if response.success, let roomData = response.data {
                        print("✅ Room created successfully: \(roomData.name) (ID: \(roomData.id))")
                        
                        // Add to backend rooms array
                        self.backendRooms.append(roomData)
                        
                        // Reset form
                        self.resetRoomForm()
                        
                        // Show success message
                        self.alertMessage = "Room '\(roomData.name)' created successfully"
                        self.showAlert = true
                        
                    } else {
                        print("❌ Room creation failed: \(response.error ?? "Unknown error")")
                        self.alertMessage = response.error ?? "Failed to create room"
                        self.showAlert = true
                    }
                    
                case .failure(let error):
                    print("❌ Room creation error: \(error)")
                    self.alertMessage = "Failed to create room: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    // Reset room form
    private func resetRoomForm() {
        newRoomName = ""
        selectedPropertyForRoom = nil
        showAddRoomField = false
    }
    
    // Load rooms for the property
    private func loadPropertiesAndRooms() {
        isLoadingRooms = true
        loadRoomsForProperty(propertyId: propertyId)
    }
    
    // Load rooms for a specific property
    private func loadRoomsForProperty(propertyId: String) {
        print("🔍 Loading rooms for property ID: \(propertyId)")
        
        roomService.getRoomsInProperty(propertyId: propertyId) { result in
            DispatchQueue.main.async {
                self.isLoadingRooms = false
                
                switch result {
                case .success(let response):
                    if response.success, let rooms = response.data {
                        print("✅ Loaded \(rooms.count) rooms for property ID: \(propertyId)")
                        
                        // Find entrance room if it exists
                        let entranceRoom = rooms.first { $0.type.lowercased() == "entrance" }
                        
                        // Set entranceObject if entrance room exists
                        if let entranceRoom = entranceRoom {
                            self.entranceObject = entranceRoom
                            print("🚪 Found existing entrance room: \(entranceRoom.name) (ID: \(entranceRoom.id))")
                        }
                        
                        // Store all rooms
                        self.backendRooms = rooms
                        
                        // Print room details for debugging
                        for room in rooms {
                            print("Room: \(room.name), Type: \(room.type), ID: \(room.id), Property: \(room.propertyId)")
                        }
                        
                        // If no rooms or no entrance room, create an entrance room
                        if rooms.isEmpty || entranceRoom == nil {
                            self.createEntranceRoom()
                        }
                    } else {
                        print("❌ Failed to load rooms: \(response.error ?? "Unknown error")")
                        self.alertMessage = "Failed to load rooms: \(response.error ?? "Unknown error")"
                        self.showAlert = true
                        
                        // If failed to load rooms, still try to create an entrance room
                        self.createEntranceRoom()
                    }
                    
                case .failure(let error):
                    print("❌ Error loading rooms: \(error)")
                    self.alertMessage = "Error loading rooms: \(error.localizedDescription)"
                    self.showAlert = true
                    
                    // If failed to load rooms, still try to create an entrance room
                    self.createEntranceRoom()
                }
            }
        }
    }
    
    // Create an entrance room if it doesn't exist
    private func createEntranceRoom() {
        print("🔓 Creating entrance room for property ID: \(propertyId)")
        
        // Show loading state
        isLoadingRooms = true
        
        // Create entrance room in backend
        roomService.createRoom(
            propertyId: propertyId,
            name: "Entrance",
            type: "entrance" // Use entrance as the type
        ) { result in
            DispatchQueue.main.async {
                self.isLoadingRooms = false
                
                switch result {
                case .success(let response):
                    if response.success, let roomData = response.data {
                        print("✅ Entrance room created successfully: \(roomData.name) (ID: \(roomData.id))")
                        
                        // Set as entrance object
                        self.entranceObject = roomData
                        
                        // Add to backend rooms array
                        self.backendRooms.append(roomData)
                    } else {
                        print("❌ Entrance room creation failed: \(response.error ?? "Unknown error")")
                    }
                    
                case .failure(let error):
                    print("❌ Entrance room creation error: \(error)")
                }
            }
        }
    }
    
    // Keep this method for backward compatibility but it's not used anymore
    private func loadRoomsForAllProperties(properties: [PropertyData]) {
        // This method is kept for backward compatibility
        // Now we use loadRoomsForProperty(propertyId:) instead
        print("⚠️ loadRoomsForAllProperties is deprecated, use loadRoomsForProperty instead")
        loadRoomsForProperty(propertyId: propertyId)
    }
    
    // MARK: - Body Components
    
    // Header component
    private var headerView: some View {
        HStack {
            Image("headerimage")
                .frame(width: 40, height: 40)
            
            Spacer()
            
            // User profile button
            Button(action: {
                // Handle profile
            }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // Title component
    private var titleView: some View {
        HStack {
            Text("Analyze your space")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // Vastu Gallery card component
    private var vastuGalleryCardView: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Vastu Gallery")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("View and manage all your Analyzed Spaces")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    // Navigate to Vastu Gallery View
                    showVastuGallery = true
                }) {
                    Text("View Library")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .frame(height: 36)
                        .background(Color(hex: "#DD8E2E"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // Room type selection component
    private var roomTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select Room Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                if isLoadingRooms {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.top, 10)
            
            if allRooms.isEmpty && !isLoadingRooms {
                Text("No rooms available. Add a room to get started.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
            
            HStack {
                Menu {
                    if allRooms.isEmpty {
                        Text("No rooms available")
                    } else {
                        ForEach(allRooms, id: \.id) { room in
                            Button(room.name) {
                                selectedRoom = room.id
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRoom != nil ? allRooms.first(where: { $0.id == selectedRoom })?.name ?? "Choose a room" : "Choose a room")
                            .foregroundColor(selectedRoom == nil ? .gray : .black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .frame(height: 36)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(allRooms.isEmpty)
                
                // Start Analysis button for room
                Button(action: {
                    if let roomId = selectedRoom, let room = allRooms.first(where: { $0.id == roomId }) {
                        checkAndStartAnalysis(for: room)
                    }
                }) {
                    Text("Start Analysis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .frame(height: 36)
                        .background(selectedRoom != nil ? Color(hex: "#DD8E2E") : Color.gray)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedRoom == nil)
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
    }
    
    // Add room form component
    private var addRoomFormView: some View {
        VStack(spacing: 10) {
            // Property selection for room
            if propertiesForSelectedType.count > 1 {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Select Property")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Menu {
                        ForEach(propertiesForSelectedType) { property in
                            Button(property.name) {
                                selectedPropertyForRoom = property
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedPropertyForRoom?.name ?? "Choose \(selectedPropertyType) property")
                                .foregroundColor(selectedPropertyForRoom == nil ? .gray : .black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            HStack {
                TextField("Enter room name", text: $newRoomName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoadingRooms)
                
                Button(action: {
                    // Cancel adding room
                    showAddRoomField = false
                    newRoomName = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingRooms)
                
                Button(action: addRoom) {
                    HStack {
                        if isLoadingRooms {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("Add")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 15)
                    .background(isLoadingRooms ? Color.gray : Color(hex: "#D4A574"))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoadingRooms || newRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 5)
        }
        .padding(.horizontal, 15)
    }
    
    // Add room button component
    private var addRoomButtonView: some View {
        
        Group {
            if isLoadingRooms {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading rooms...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 15)
            } else {
                HStack(alignment: .center) {
                    Button(action: {
                        showAddRoomField = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            Text("Add a Room")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color(hex: "#DD8E2E"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .frame(height: 36)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#DD8E2E"), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 15)
            }
        }
    }
    
    // Room card header component
    private var roomCardHeaderView: some View {
        VStack(spacing: 15) {
            VStack {
                HStack {
                    Text("Analyze a Specific Room")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Check the Vastu of any room, one by one.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
        }
        
    }
   
    // Entrance card component
    private var entranceCardView: some View {
        VStack(spacing: 15) {
           
               
                
                VStack(alignment: .leading, spacing: 8) {
                    Image("property")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        
                        .cornerRadius(15)
                    HStack {
                        Text("Analyze Your Main Entrance")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.leading, 15)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Unlock the energy of your home's main entry.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 15)
                            Spacer()
                    }
                    
                    // Start Analysis button
                    HStack {
                        Spacer()
                        Button(action: {
                            if let entranceRoom = entranceObject {
                                checkAndStartEntranceAnalysis(for: entranceRoom)
                            } else {
                                alertMessage = "Entrance room not found. Please try again."
                                showAlert = true
                            }
                        }) {
                            Text("Start Analysis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .background(Color(hex: "#DD8E2E"))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: UIScreen.main.bounds.width / 3)
                    }
                    
                }
                .padding(.bottom, 15)
            
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // Photo limit checks
    private func checkAndStartAnalysis(for room: RoomData) {
        photoService.getPhotosInRoom(roomId: room.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let existing = response.data?.count ?? 0
                    let allowed = max(0, 4 - existing)
                    if allowed <= 0 {
                        self.alertMessage = "You already have 4 photos for \(room.name). Delete some to take more."
                        self.showAlert = true
                    } else {
                        self.existingPhotosForCamera = existing
                        self.maxPhotosForCamera = 4
                        self.showCameraView = true
                    }
                case .failure(let error):
                    self.alertMessage = "Failed to check existing photos: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    private func checkAndStartEntranceAnalysis(for entranceRoom: RoomData) {
        photoService.getPhotosInRoom(roomId: entranceRoom.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let existing = response.data?.count ?? 0
                    let allowed = max(0, 4 - existing)
                    if allowed <= 0 {
                        self.alertMessage = "You already have 4 photos for \(entranceRoom.name). Delete some to take more."
                        self.showAlert = true
                    } else {
                        self.existingPhotosForCamera = existing
                        self.maxPhotosForCamera = 4
                        self.showEntranceCameraView = true
                    }
                case .failure(let error):
                    self.alertMessage = "Failed to check existing photos: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with logo
                headerView
                
                // Title
                titleView
                
                // Main Entrance Card
                entranceCardView
                
                // Analyze a Specific Room Card
                VStack {
                    roomCardHeaderView
                   
                    
                    // Add Room button with loading state
                    addRoomButtonView
                    
                    // Add Room Form
                    if showAddRoomField {
                        addRoomFormView
                    }
                    
                    // Select Room Type dropdown
                    roomTypeSelectionView
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 20)
                
                // Your Vastu Gallery Card
                vastuGalleryCardView
                
                Spacer(minLength: 100) // Space for bottom navigation
            }
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            loadPropertiesAndRooms()
        }
        // Camera for regular room analysis
        .fullScreenCover(isPresented: $showCameraView) {
            if let roomId = selectedRoom, let room = allRooms.first(where: { $0.id == roomId }) {
                RoomCameraView(
                    roomId: room.id,
                    roomName: room.name,
                    maxPhotos: maxPhotosForCamera,
                    existingPhotosCount: existingPhotosForCamera
                )
            }
        }
        // Camera for entrance room analysis
        .fullScreenCover(isPresented: $showEntranceCameraView) {
            if let entranceRoom = entranceObject {
                RoomCameraView(
                    roomId: entranceRoom.id,
                    roomName: entranceRoom.name,
                    maxPhotos: maxPhotosForCamera,
                    existingPhotosCount: existingPhotosForCamera
                )
            }
        }
        // Vastu Gallery view
        .fullScreenCover(isPresented: $showVastuGallery) {
            // Using VastuGalleryView from VastuGalleryScreen.swift
            VastuGalleryView()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Room Management"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
