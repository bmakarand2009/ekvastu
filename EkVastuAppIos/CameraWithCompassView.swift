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
            
            DispatchQueue.main.async {
                view.setNeedsLayout()
            }
            
            print("Camera preview view created with session running: \(session.isRunning)")
            return view
        }
        
        func updateUIView(_ uiView: VideoPreviewView, context: Context) {
            if uiView.session != session {
                uiView.session = session
            }
            
            print("Camera preview view updated, session running: \(session.isRunning)")
        }
    }
    
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
                        .frame(width: 40, height: 40)
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
                    
                    // Compass overlay at the bottom (iOS-style)
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
            compassService.startUpdates()
            cameraService.setupAndStartCaptureSession()
            setupNotificationObserver()
            
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
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingPopupPreview = false
                    }
                
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
            
            let finalImage = self.createCompositeImage(originalImage: originalImage, heading: self.compassService.heading)
            
            DispatchQueue.main.async {
                self.capturedImages.append(finalImage)
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func createCompositeImage(originalImage: UIImage, heading: Double) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        
        let finalImage = renderer.image { context in
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
            
            let ctx = context.cgContext
            
            // Draw header image at the top
            if let headerImage = UIImage(named: "headerimage") {
                let headerHeight: CGFloat = 40
                let headerWidth: CGFloat = 40
                let headerRect = CGRect(x: 10, y: 10, width: headerWidth, height: headerHeight)
                headerImage.draw(in: headerRect)
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
            // The compass card rotates, not the needle
            ctx.rotate(by: CGFloat(360 - heading) * .pi / 180)
            
            // Draw degree markers
            for i in 0..<36 {
                ctx.saveGState()
                ctx.rotate(by: CGFloat(i) * 30 * .pi / 180)
                
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
    
    // iOS-style compass overlay view
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
                            
                            // Cardinal directions (positioned correctly)
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
                        
                        // Fixed needle pointing up - simple and clean
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
            }.padding(.bottom, 30)
        }
    }
}
