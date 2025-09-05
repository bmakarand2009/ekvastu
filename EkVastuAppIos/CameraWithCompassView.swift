import SwiftUI
import AVFoundation
import CoreLocation

struct CameraWithCompassView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var compassService = CompassService.shared
    @Binding var capturedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showingPhotoPreview = false
    @State private var showingPopupPreview = false
    @State private var showThumbnails = true
    
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
            
            // Force layout to ensure proper sizing
            DispatchQueue.main.async {
                view.setNeedsLayout()
            }
            
            print("Camera preview view created with session running: \(session.isRunning)")
            return view
        }
        
        func updateUIView(_ uiView: VideoPreviewView, context: Context) {
            // Ensure the session is set and the view is properly laid out
            if uiView.session != session {
                uiView.session = session
            }
            
            print("Camera preview view updated, session running: \(session.isRunning)")
        }
    }
    
    // Observer for dismissing the camera view
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("DismissCameraView"), object: nil, queue: .main) { _ in
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    var body: some View {
        ZStack {
            // Camera preview - base layer
            if cameraService.isCameraReady {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.black)
                    .zIndex(0)
                
                // UI Overlay elements - top layer
                VStack(spacing: 0) {
                    // Header image at the top
                    Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .padding(.top, 20)
                    
                    // Thumbnails row if there are captured images
                    if showThumbnails && !capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<capturedImages.count, id: \.self) { index in
                                    Button(action: {
                                        selectedImage = capturedImages[index]
                                        showingPopupPreview = true
                                    }) {
                                        Image(uiImage: capturedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white, lineWidth: 2)
                                            )
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
                        
                        // Capture button
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
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
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
        .alert(isPresented: $cameraService.showCameraAlert) {
            Alert(
                title: Text("Camera Error"),
                message: Text(cameraService.cameraError?.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    // Dismiss the view when there's a camera error
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            // Start the compass first since it's less likely to fail
            compassService.startUpdates()
            
            // Setup camera with a timeout
            cameraService.setupAndStartCaptureSession()
            
            // Setup notification observer for dismissing camera view
            setupNotificationObserver()
            
            // Add a timeout to detect if camera initialization is stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if !self.cameraService.isCameraReady {
                    self.errorMessage = "Camera initialization timed out. Please try again."
                    self.showError = true
                }
            }
        }
        .onDisappear {
            cameraService.stopSession()
            compassService.stopUpdates()
        }
        .sheet(isPresented: $showingPhotoPreview) {
            // Use the new FullScreenPhotoView for photo preview
            if let image = selectedImage {
                FullScreenPhotoView(image: image)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("No image to preview")
                    .foregroundColor(.white)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .overlay(Group {
            if showingPopupPreview, let image = selectedImage {
                // Semi-transparent background
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Close popup when tapping outside the image
                        showingPopupPreview = false
                    }
                
                // Image popup with close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingPopupPreview = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(10)
                        }
                    }
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
                .padding()
            }
        })
    }
    
    private func capturePhotoWithCompass() {
        cameraService.capturePhoto { image, error in
            guard let originalImage = image else {
                print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Create a composite image with compass overlay and header
            let finalImage = self.createCompositeImage(originalImage: originalImage, heading: self.compassService.heading)
            
            // Save the image and dismiss the camera
            DispatchQueue.main.async {
                // Add to captured images array
                self.capturedImages.append(finalImage)
                
                // Automatically dismiss the camera view after capturing
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func createCompositeImage(originalImage: UIImage, heading: Double) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        
        let finalImage = renderer.image { context in
            // Draw the original image
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
            
            // Get the context for drawing
            let ctx = context.cgContext
            
            // Draw header image at the top (50px height)
            if let headerImage = UIImage(named: "headerimage") {
                let headerHeight: CGFloat = 50
                let headerWidth = originalImage.size.width
                let headerRect = CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight)
                headerImage.draw(in: headerRect)
            }
            
            // Draw compass at the bottom
            let compassSize: CGFloat = 120
            let compassX = originalImage.size.width / 2 - compassSize / 2
            let compassY = originalImage.size.height - compassSize - 20
            
            // Draw compass background
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            ctx.fillEllipse(in: CGRect(x: compassX, y: compassY, width: compassSize, height: compassSize))
            
            // Draw compass directions
            let directions = ["N", "E", "S", "W"]
            let positions = [
                CGPoint(x: compassX + compassSize/2, y: compassY + 15), // N
                CGPoint(x: compassX + compassSize - 15, y: compassY + compassSize/2), // E
                CGPoint(x: compassX + compassSize/2, y: compassY + compassSize - 15), // S
                CGPoint(x: compassX + 15, y: compassY + compassSize/2) // W
            ]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            for (index, direction) in directions.enumerated() {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
                
                let textSize = (direction as NSString).size(withAttributes: attributes)
                let point = positions[index]
                let textRect = CGRect(
                    x: point.x - textSize.width/2,
                    y: point.y - textSize.height/2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                (direction as NSString).draw(in: textRect, withAttributes: attributes)
            }
            
            // Draw compass needle
            ctx.saveGState()
            ctx.translateBy(x: compassX + compassSize/2, y: compassY + compassSize/2)
            ctx.rotate(by: CGFloat(compassService.heading) * .pi / 180)
            
            // Red needle
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fill(CGRect(x: -1, y: -45, width: 2, height: 45))
            
            // Center pin
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fillEllipse(in: CGRect(x: -5, y: -5, width: 10, height: 10))
            
            ctx.restoreGState()
            
            // Draw heading text
            let headingText = "\(Int(compassService.heading))°"
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let headingRect = CGRect(
                x: compassX + compassSize/2 - 20,
                y: compassY + compassSize - 20,
                width: 40,
                height: 20
            )
            
            (headingText as NSString).draw(in: headingRect, withAttributes: headingAttributes)
        }
        
        return finalImage
    }
    
    // Clock-like compass overlay view
    func CompassOverlayView(heading: Double) -> some View {
        VStack {
            Spacer()
            
            ZStack {
                // Semi-transparent background
                Rectangle()
                    .fill(Color.black.opacity(0.2)) // More transparent background
                    .frame(height: 180) // Increased height for larger compass
                    .allowsHitTesting(false) // Allow interactions to pass through
                
                VStack(spacing: 10) {
                    // Direction text
                    Text(compassService.direction)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 1, y: 1) // Add shadow for better visibility
                    
                    // Clock-like compass
                    ZStack {
                        // Outer circle with transparency
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 3)
                            .frame(width: 160, height: 160) // Double the size
                            .background(Circle().fill(Color.black.opacity(0.15)))
                        
                        // Degree markers
                        ForEach(0..<12, id: \.self) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 3, height: i % 3 == 0 ? 20 : 10)
                                .offset(y: -70)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }
                        
                        // Cardinal directions with correct positioning
                        Group {
                            // North at top
                            Text("N")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.red)
                                .offset(y: -85)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: 30, height: 30)
                                )
                                .shadow(color: .black, radius: 1)
                            
                            // East at right
                            Text("E")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 85)
                                .shadow(color: .black, radius: 1)
                                
                            // South at bottom
                            Text("S")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: 85)
                                .shadow(color: .black, radius: 1)
                                
                            // West at left
                            Text("W")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: -85)
                                .shadow(color: .black, radius: 1)
                        }
                        
                        // Compass needle
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4, height: 70)
                            .offset(y: -35)
                            .rotationEffect(.degrees(-heading))
                        
                        // Center pin
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        
                        // Degree text
                        Text(String(format: "%.0f°", heading))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1)
                            .offset(y: 20)
                    }
                    .allowsHitTesting(false) // Allow touches to pass through
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CompassDirectionMiniView: View {
    let direction: String
    
    var body: some View {
        VStack {
            Text(direction)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .frame(width: 100, height: 100)
        .rotationEffect(angle(for: direction))
    }
    
    private func angle(for direction: String) -> Angle {
        switch direction {
        case "N": return .degrees(0)
        case "E": return .degrees(90)
        case "S": return .degrees(180)
        case "W": return .degrees(270)
        default: return .degrees(0)
        }
    }
}
