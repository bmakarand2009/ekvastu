import SwiftUI
import AVFoundation
import CoreLocation

// Model to store captured photo information
struct CapturedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    var assetId: String? // Cloudinary asset ID after upload
    var publicId: String? // Cloudinary public ID after upload
    var url: String? // Cloudinary URL after upload
    var isUploading = false
    var isUploaded = false
}

struct RoomCameraView: View {
    // Camera and compass services
    @StateObject private var cameraService = CameraService()
    @StateObject private var compassService = CompassService.shared
    @StateObject private var cloudinaryService = CloudinaryService()
    
    // Environment
    @Environment(\.presentationMode) var presentationMode
    
    // Room information
    let roomId: String
    let roomName: String
    let maxPhotos: Int
    let existingPhotosCount: Int
    
    // Alert handling with enum
    enum AlertType: Identifiable {
        case error(message: String)
        case cameraError(message: String)
        case retakeConfirmation
        
        var id: Int {
            switch self {
            case .error: return 0
            case .cameraError: return 1
            case .retakeConfirmation: return 2
            }
        }
    }
    
    // State variables
    @State private var capturedPhotos: [CapturedPhoto] = []
    @State private var currentPhoto: UIImage? = nil
    @State private var alertItem: AlertType? = nil
    @State private var showingPhotoPreview = false
    @State private var selectedPhotoIndex: Int? = nil
    @State private var isCameraActive = true
    @State private var showEvaluation = false
    @State private var actualExistingPhotosCount: Int = 0 // Track actual count from backend
    
    // Tenant config for Cloudinary
    private let tenantConfig = TenantConfigManager.shared
    
    // Photo service for API calls
    private let photoService = PhotoService.shared
    
    var body: some View {
        ZStack {
            // Camera preview when active
            if isCameraActive {
                cameraPreviewLayer
            } else if let photo = currentPhoto {
                // Photo review screen
                photoReviewLayer(photo: photo)
            }
        }
        .fullScreenCover(isPresented: $showEvaluation) {
            EvaluationQuestionsView(roomId: roomId, roomName: roomName)
        }
        // Single alert with multiple types
        .alert(item: $alertItem) { item in
            switch item {
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .cameraError(let message):
                return Alert(
                    title: Text("Camera Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            case .retakeConfirmation:
                return Alert(
                    title: Text("Retake Photo?"),
                    message: Text("Are you sure you want to discard this photo and take a new one?"),
                    primaryButton: .destructive(Text("Retake")) {
                        currentPhoto = nil
                        isCameraActive = true
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraService.stopSession()
            compassService.stopUpdates()
        }
    }
    
    // MARK: - Camera Preview Layer
    private var cameraPreviewLayer: some View {
        ZStack {
            if cameraService.isCameraReady {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.black)
                    .zIndex(0)
                
                // UI Overlay elements
                VStack(spacing: 0) {
                    // Header with room name
                    HStack {
                        Image("headerimage")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        
                        Text(roomName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                    .background(Color.black.opacity(0.5))
                    
                    // Thumbnails row if there are captured images
                    if !capturedPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<capturedPhotos.count, id: \.self) { index in
                                    Button(action: {
                                        selectedPhotoIndex = index
                                        showingPhotoPreview = true
                                    }) {
                                        ZStack {
                                            Image(uiImage: capturedPhotos[index].image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                            
                                            // Show upload status indicator
                                            if capturedPhotos[index].isUploading {
                                                Color.black.opacity(0.5)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else if capturedPhotos[index].isUploaded {
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                            .padding(5)
                                                            .background(Circle().fill(Color.white.opacity(0.8)))
                                                    }
                                                }
                                                .padding(5)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .frame(height: 80)
                        .background(Color.black.opacity(0.3))
                    }
                    
                    Spacer()
                    
                    // Compass overlay at the bottom
                    CompassOverlayView(heading: compassService.heading)
                    
                    // Capture button centered
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            capturePhotoWithCompass()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .disabled(capturedPhotos.count >= (maxPhotos - actualExistingPhotosCount))
                        .opacity(capturedPhotos.count >= (maxPhotos - actualExistingPhotosCount) ? 0.5 : 1)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                    
                    // Photo count indicator
                    Text("\(actualExistingPhotosCount + capturedPhotos.count)/\(maxPhotos) Photos")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.bottom, 10)
                }
            } else {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Text("Initializing Camera...")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showingPhotoPreview) {
            if let index = selectedPhotoIndex, index < capturedPhotos.count {
                FullScreenPhotoView(image: capturedPhotos[index].image)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    // MARK: - Photo Review Layer
    private func photoReviewLayer(photo: UIImage) -> some View {
        ZStack {
            // Display the captured photo
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header with room name
                HStack {
                    Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                    
                    Text(roomName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 10)
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 30) {
                    // Retake button
                    Button(action: {
                        alertItem = .retakeConfirmation
                    }) {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                            Text("Retake")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(10)
                    }
                    
                    // Save button
                    Button(action: {
                        saveAndUploadPhoto(photo)
                    }) {
                        VStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                            Text("Save")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(10)
                    }
                    
                    // Next button: go to Evaluation screen without saving photo
                    Button(action: {
                        // Stop camera session before navigating
                        cameraService.stopSession()
                        compassService.stopUpdates()
                        
                        // Close camera and navigate to evaluation
                        isCameraActive = false
                        currentPhoto = nil
                        showEvaluation = true
                    }) {
                        VStack {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 24))
                            Text("Next")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Camera Preview View
    struct CameraPreviewView: UIViewRepresentable {
        let session: AVCaptureSession
        
        class VideoPreviewView: UIView {
            override class var layerClass: AnyClass {
                return AVCaptureVideoPreviewLayer.self
            }
            
            var videoPreviewLayer: AVCaptureVideoPreviewLayer {
                return layer as! AVCaptureVideoPreviewLayer
            }
            
            var session: AVCaptureSession? {
                get {
                    return videoPreviewLayer.session
                }
                set {
                    videoPreviewLayer.session = newValue
                }
            }
        }
        
        func makeUIView(context: Context) -> VideoPreviewView {
            let view = VideoPreviewView()
            view.backgroundColor = .black
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            view.videoPreviewLayer.connection?.videoOrientation = .portrait
            view.session = session
            
            DispatchQueue.main.async {
                view.setNeedsLayout()
            }
            
            return view
        }
        
        func updateUIView(_ uiView: VideoPreviewView, context: Context) {
            if uiView.session != session {
                uiView.session = session
            }
        }
    }
    
    // MARK: - Compass Overlay View
    func CompassOverlayView(heading: Double) -> some View {
        VStack {
            Spacer()
            
            ZStack {
                // Semi-transparent background
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(height: 180)
                    .allowsHitTesting(false)
                
                VStack(spacing: 10) {
                    // Direction text
                    Text(getDirectionText(for: heading))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                    
                    // iOS-style compass
                    ZStack {
                        // Outer circle
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                            .frame(width: 160, height: 160)
                            .background(Circle().fill(Color.black.opacity(0.15)))
                        
                        // Compass rose that rotates
                        ZStack {
                            // Degree markers
                            ForEach(0..<36, id: \.self) { i in
                                Rectangle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: i % 3 == 0 ? 3 : 1.5, height: i % 3 == 0 ? 15 : 8)
                                    .offset(y: -70)
                                    .rotationEffect(.degrees(Double(i * 10)))
                            }
                            
                            // Cardinal directions
                            Group {
                                // North - at top when heading is 0
                                Text("N")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(y: -85)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 30, height: 30)
                                    )
                                    .shadow(color: .black, radius: 1)
                                
                                // East - at right when heading is 0
                                Text("E")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 85)
                                    .shadow(color: .black, radius: 1)
                                    
                                // South - at bottom when heading is 0
                                Text("S")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(y: 85)
                                    .shadow(color: .black, radius: 1)
                                    
                                // West - at left when heading is 0
                                Text("W")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: -85)
                                    .shadow(color: .black, radius: 1)
                            }
                        }
                        .rotationEffect(.degrees(360 - heading)) // Rotate opposite to heading
                        .animation(.easeInOut(duration: 0.3), value: heading)
                        
                        // Fixed needle pointing up
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 3, height: 70)
                            .offset(y: -35)
                        
                        // Center pin
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black, radius: 2)
                        
                        // Degree text below compass
                        Text(String(format: "%.0f°", heading))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1)
                            .offset(y: 100)
                    }
                    .allowsHitTesting(false)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Helper Methods
    private func setupCamera() {
        compassService.startUpdates()
        cameraService.setupAndStartCaptureSession()
        
        // Load existing photos count from backend
        loadExistingPhotosCount()
        
        // Set a timeout for camera initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if !self.cameraService.isCameraReady {
                self.alertItem = .error(message: "Camera initialization timed out. Please try again.")
            }
        }
        
        // Observe camera errors
        NotificationCenter.default.addObserver(forName: NSNotification.Name("CameraError"), object: nil, queue: .main) { notification in
            if let error = notification.userInfo?["error"] as? Error {
                self.alertItem = .cameraError(message: error.localizedDescription)
            }
        }
    }
    
    // Load existing photos count from backend
    private func loadExistingPhotosCount() {
        print("🔍 Loading existing photos count for room ID: \(roomId)")
        
        photoService.getPhotosInRoom(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let count = response.data?.count ?? 0
                    self.actualExistingPhotosCount = count
                    print("✅ Loaded \(count) existing photos for room ID: \(self.roomId)")
                case .failure(let error):
                    print("❌ Failed to load existing photos: \(error)")
                    // Use the passed existingPhotosCount as fallback
                    self.actualExistingPhotosCount = self.existingPhotosCount
                }
            }
        }
    }
    
    private func capturePhotoWithCompass() {
        // Check if we've reached the maximum number of photos
        guard capturedPhotos.count < maxPhotos else {
            alertItem = .error(message: "Maximum number of photos (\(maxPhotos)) reached.")
            return
        }
        
        cameraService.capturePhoto { image, error in
            guard let originalImage = image else {
                print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.alertItem = .error(message: "Failed to capture photo: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }
            
            // Create composite image with compass and room name
            let finalImage = self.createCompositeImage(originalImage: originalImage, heading: self.compassService.heading)
            
            DispatchQueue.main.async {
                // Show the captured photo for review
                self.currentPhoto = finalImage
                self.isCameraActive = false
            }
        }
    }
    
    private func saveAndUploadPhoto(_ photo: UIImage) {
        // Add to captured photos array
        let newPhoto = CapturedPhoto(image: photo)
        
        DispatchQueue.main.async {
            // Add to captured photos array
            var updatedPhoto = newPhoto
            updatedPhoto.isUploading = true
            self.capturedPhotos.append(updatedPhoto)
            
            // Get the index of the newly added photo
            let photoIndex = self.capturedPhotos.count - 1
            
            // Upload to Cloudinary
            Task {
                do {
                    // Upload to Cloudinary
                    let uploadResponse = try await self.cloudinaryService.uploadImage(photo)
                    print("✅ Photo uploaded to Cloudinary: \(uploadResponse.assetId)")
                    
                    // Update photo with Cloudinary info
                    DispatchQueue.main.async {
                        self.capturedPhotos[photoIndex].assetId = uploadResponse.assetId
                        self.capturedPhotos[photoIndex].publicId = uploadResponse.publicId
                        self.capturedPhotos[photoIndex].url = uploadResponse.secureUrl
                        self.capturedPhotos[photoIndex].isUploading = false
                        
                        // Save to backend
                        Task {
                            do {
                                let photoResponse = try await self.photoService.addPhotoWithURL(
                                    roomId: self.roomId,
                                    cloudName: self.tenantConfig.cloudinaryCloudName,
                                    uri: uploadResponse.secureUrl
                                )
                                
                                print("✅ Photo saved to backend: \(photoResponse.data?.id ?? "unknown")")
                                
                                DispatchQueue.main.async {
                                    self.capturedPhotos[photoIndex].isUploaded = true
                                    
                                    // If we've reached remaining slots, dismiss the camera view
                                    if self.capturedPhotos.count >= (self.maxPhotos - self.existingPhotosCount) {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            } catch {
                                print("❌ Failed to save photo to backend: \(error)")
                                DispatchQueue.main.async {
                                    self.alertItem = .error(message: "Failed to save photo: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                } catch {
                    print("❌ Failed to upload photo to Cloudinary: \(error)")
                    DispatchQueue.main.async {
                        self.capturedPhotos[photoIndex].isUploading = false
                        self.alertItem = .error(message: "Failed to upload photo: \(error.localizedDescription)")
                    }
                }
            }
            
            // Return to camera view if not at remaining slots
            if self.capturedPhotos.count < (self.maxPhotos - self.actualExistingPhotosCount) {
                // First stop the current camera session
                self.cameraService.stopSession()
                self.compassService.stopUpdates()
                
                // Reset UI state
                self.currentPhoto = nil
                self.isCameraActive = true
                
                // Restart camera session
                self.setupCamera()
            } else {
                // If this was the last allowed photo, dismiss the camera view
                self.cameraService.stopSession()
                self.compassService.stopUpdates()
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func createCompositeImage(originalImage: UIImage, heading: Double) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        
        let finalImage = renderer.image { context in
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
            
            let ctx = context.cgContext
            
            // Draw header with room name at the top
            let headerHeight: CGFloat = 60
            let headerWidth = originalImage.size.width
            let headerRect = CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight)
            
            // Draw semi-transparent background for header
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            ctx.fill(headerRect)
            
            // Draw header image
            if let headerImage = UIImage(named: "headerimage") {
                let imageHeight = headerHeight - 10
                let imageWidth = imageHeight * (headerImage.size.width / headerImage.size.height)
                let imageRect = CGRect(x: 10, y: 5, width: imageWidth, height: imageHeight)
                headerImage.draw(in: imageRect)
                
                // Draw room name text
                let roomNameAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.white
                ]
                
                let roomNameRect = CGRect(
                    x: imageRect.maxX + 10,
                    y: 5,
                    width: headerWidth - imageRect.maxX - 20,
                    height: headerHeight - 10
                )
                
                (roomName as NSString).draw(in: roomNameRect, withAttributes: roomNameAttributes)
            }
            
            // Calculate dimensions for compass
            let compassSize: CGFloat = min(originalImage.size.width * 0.8, 320)
            let compassX = originalImage.size.width / 2 - compassSize / 2
            let compassY = originalImage.size.height - compassSize - 60
            
            // Draw semi-transparent background for compass area
            let backgroundHeight: CGFloat = compassSize + 80
            let backgroundRect = CGRect(x: 0, y: originalImage.size.height - backgroundHeight,
                                       width: originalImage.size.width, height: backgroundHeight)
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            ctx.fill(backgroundRect)
            
            // Draw direction text at the top of compass
            let directionText = getDirectionText(for: heading)
            let directionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.white,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }()
            ]
            
            let directionRect = CGRect(
                x: 0,
                y: originalImage.size.height - backgroundHeight + 20,
                width: originalImage.size.width,
                height: 40
            )
            
            (directionText as NSString).draw(in: directionRect, withAttributes: directionAttributes)
            
            // Draw compass circle
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(3)
            ctx.strokeEllipse(in: CGRect(x: compassX, y: compassY, width: compassSize, height: compassSize))
            
            // Save state and translate to compass center
            ctx.saveGState()
            ctx.translateBy(x: compassX + compassSize/2, y: compassY + compassSize/2)
            
            // Rotate the entire compass rose to match iOS behavior
            ctx.rotate(by: CGFloat(360 - heading) * .pi / 180)
            
            // Draw degree markers
            for i in 0..<36 {
                ctx.saveGState()
                ctx.rotate(by: CGFloat(i) * 10 * .pi / 180)
                
                let markerHeight: CGFloat = i % 3 == 0 ? 20 : 10
                ctx.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
                ctx.fill(CGRect(x: -1.5, y: -compassSize/2, width: 3, height: markerHeight))
                
                ctx.restoreGState()
            }
            
            // Draw cardinal directions (these rotate with the compass)
            let directions = ["N", "E", "S", "W"]
            let angles = [0, 90, 180, 270]
            
            for (index, direction) in directions.enumerated() {
                ctx.saveGState()
                ctx.rotate(by: CGFloat(angles[index]) * .pi / 180)
                
                let color = direction == "N" ? UIColor.red : UIColor.white
                let fontSize: CGFloat = direction == "N" ? 40 : 36
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                    .foregroundColor: color,
                ]
                
                // Position the text
                let textSize = (direction as NSString).size(withAttributes: attributes)
                let yOffset = -compassSize/2 + 30
                let textRect = CGRect(
                    x: -textSize.width/2,
                    y: yOffset,
                    width: textSize.width,
                    height: textSize.height
                )
                
                // Draw white circle background for North
                if direction == "N" {
                    ctx.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
                    ctx.fillEllipse(in: CGRect(
                        x: -20,
                        y: yOffset,
                        width: 40,
                        height: 40
                    ))
                }
                
                (direction as NSString).draw(in: textRect, withAttributes: attributes)
                
                ctx.restoreGState()
            }
            
            ctx.restoreGState()
            
            // Draw fixed needle pointing up (NOT rotating)
            ctx.saveGState()
            ctx.translateBy(x: compassX + compassSize/2, y: compassY + compassSize/2)
            
            // Red needle pointing up
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fill(CGRect(x: -4, y: -compassSize/2 + 20, width: 8, height: compassSize/2 - 20))
            
            // Center pin
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fillEllipse(in: CGRect(x: -16, y: -16, width: 32, height: 32))
            
            ctx.restoreGState()
            
            // Draw heading text
            let headingText = "\(Int(heading))°"
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.white,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }()
            ]
            
            let headingRect = CGRect(
                x: compassX,
                y: compassY + compassSize/2 + 30,
                width: compassSize,
                height: 40
            )
            
            (headingText as NSString).draw(in: headingRect, withAttributes: headingAttributes)
        }
        
        return finalImage
    }
    
    private func getDirectionText(for heading: Double) -> String {
        switch heading {
        case 0..<22.5, 337.5...360:
            return "N"
        case 22.5..<67.5:
            return "NE"
        case 67.5..<112.5:
            return "E"
        case 112.5..<157.5:
            return "SE"
        case 157.5..<202.5:
            return "S"
        case 202.5..<247.5:
            return "SW"
        case 247.5..<292.5:
            return "W"
        case 292.5..<337.5:
            return "NW"
        default:
            return "N"
        }
    }
}

// Using the existing FullScreenPhotoView from FullScreenPhotoView.swift
