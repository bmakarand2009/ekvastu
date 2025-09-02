import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    @State private var capturedImage: UIImage?
    @State private var showingCapturedImage = false
    
    var body: some View {
        ZStack {
            if cameraService.isCameraReady {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            cameraService.capturePhoto { image, error in
                                guard let image = image else {
                                    print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
                                    return
                                }
                                
                                capturedImage = image
                                showingCapturedImage = true
                            }
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
                        .padding()
                }
            }
        }
        .alert(isPresented: $cameraService.showCameraAlert) {
            Alert(
                title: Text("Camera Error"),
                message: Text(cameraService.cameraError?.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingCapturedImage) {
            if let image = capturedImage {
                CapturedImageView(image: image, isPresented: $showingCapturedImage)
            }
        }
        .onAppear {
            cameraService.setupAndStartCaptureSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct CapturedImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                HStack(spacing: 40) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Retake")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isSaving = true
                        
                        // Save image to photo library
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        
                        // Simulate saving delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSaving = false
                            isPresented = false
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                                .background(Color(hex: "#8B4513"))
                                .cornerRadius(10)
                        } else {
                            Text("Use Photo")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#8B4513"))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Captured Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
