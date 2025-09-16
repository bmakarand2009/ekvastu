import Foundation
import UIKit
import AVFoundation
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var photo: UIImage?
    @Published var showCameraAlert = false
    @Published var cameraError: CameraError?
    @Published var isCameraReady = false
    
    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case createCaptureInput(Error)
        case deniedAuthorization
        case restrictedAuthorization
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is unavailable"
            case .cannotAddInput:
                return "Cannot add capture input to session"
            case .cannotAddOutput:
                return "Cannot add video output to session"
            case .createCaptureInput(let error):
                return "Error creating capture input: \(error.localizedDescription)"
            case .deniedAuthorization:
                return "Camera access was denied"
            case .restrictedAuthorization:
                return "Camera access is restricted"
            }
        }
    }
    
    let session = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput?
    let output = AVCapturePhotoOutput()
    
    private var isCaptureSessionConfigured = false
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        print("Checking camera permissions...")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            print("Camera permission not determined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                print("Camera authorization result: \(authorized)")
                if !authorized {
                    DispatchQueue.main.async {
                        self.cameraError = .deniedAuthorization
                        self.showCameraAlert = true
                    }
                    completion(false)
                } else {
                    completion(true)
                }
            }
        case .restricted:
            print("Camera access restricted")
            DispatchQueue.main.async {
                self.cameraError = .restrictedAuthorization
                self.showCameraAlert = true
            }
            completion(false)
        case .denied:
            print("Camera access denied")
            DispatchQueue.main.async {
                self.cameraError = .deniedAuthorization
                self.showCameraAlert = true
            }
            completion(false)
        case .authorized:
            print("Camera access authorized")
            completion(true)
        @unknown default:
            print("Unknown camera authorization status")
            completion(false)
        }
    }
    
    func setupAndStartCaptureSession() {
        // Reset state
        DispatchQueue.main.async {
            self.isCameraReady = false
        }
        
        checkPermissions { [weak self] granted in
            guard let self = self, granted else { 
                DispatchQueue.main.async {
                    self?.cameraError = .deniedAuthorization
                    self?.showCameraAlert = true
                }
                return 
            }
            
            print("Camera permissions granted, configuring session")
            self.sessionQueue.async {
                // Stop session if it's running
                if self.session.isRunning {
                    self.session.stopRunning()
                }
                
                // Reset session configuration
                if self.isCaptureSessionConfigured {
                    self.session.beginConfiguration()
                    for input in self.session.inputs {
                        self.session.removeInput(input)
                    }
                    for output in self.session.outputs {
                        self.session.removeOutput(output)
                    }
                    self.session.commitConfiguration()
                    self.isCaptureSessionConfigured = false
                }
                
                self.configureCaptureSession { success in
                    guard success else { 
                        print("Failed to configure capture session")
                        DispatchQueue.main.async {
                            self.cameraError = .cameraUnavailable
                            self.showCameraAlert = true
                        }
                        return 
                    }
                    
                    print("Starting camera session")
                    self.session.startRunning()
                    
                    // Ensure UI updates happen on main thread
                    DispatchQueue.main.async {
                        print("Camera is now ready")
                        self.isCameraReady = true
                    }
                }
            }
        }
    }
    
    func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        guard !isCaptureSessionConfigured else { 
            print("Capture session already configured")
            return completionHandler(true) 
        }
        
        print("Beginning session configuration")
        session.beginConfiguration()
        
        print("Finding camera device")
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let camera = videoDevice else {
            print("Camera unavailable")
            session.commitConfiguration() // Make sure to commit before returning
            DispatchQueue.main.async {
                self.cameraError = .cameraUnavailable
                self.showCameraAlert = true
            }
            completionHandler(false)
            return
        }
        
        print("Found camera device: \(camera.localizedName)")
        
        do {
            print("Creating video device input")
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                print("Adding video input to session")
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("Cannot add video input to session")
                session.commitConfiguration() // Make sure to commit before returning
                DispatchQueue.main.async {
                    self.cameraError = .cannotAddInput
                    self.showCameraAlert = true
                }
                completionHandler(false)
                return
            }
        } catch {
            print("Error creating capture input: \(error.localizedDescription)")
            session.commitConfiguration() // Make sure to commit before returning
            DispatchQueue.main.async {
                self.cameraError = .createCaptureInput(error)
                self.showCameraAlert = true
            }
            completionHandler(false)
            return
        }
        
        if session.canAddOutput(output) {
            print("Adding photo output to session")
            session.addOutput(output)
            
            // Configure photo output based on device capabilities
            if #available(iOS 16.0, *) {
                // Get the active format's supported dimensions from the video device input
                if let device = videoDeviceInput?.device {
                    let activeFormat = device.activeFormat
                    let supportedDimensions = activeFormat.supportedMaxPhotoDimensions
                    // Use the highest resolution available
                    let sortedDimensions = supportedDimensions.sorted { first, second in
                        let firstPixels = Int(first.width) * Int(first.height)
                        let secondPixels = Int(second.width) * Int(second.height)
                        return firstPixels > secondPixels
                    }
                    if let maxDimension = sortedDimensions.first {
                        output.maxPhotoDimensions = maxDimension
                        print("Set maxPhotoDimensions to: \(maxDimension.width)x\(maxDimension.height)")
                    }
                }
            } else {
                // Fallback for older iOS versions
                output.isHighResolutionCaptureEnabled = true
            }
            output.maxPhotoQualityPrioritization = .quality
        } else {
            print("Cannot add photo output to session")
            session.commitConfiguration() // Make sure to commit before returning
            DispatchQueue.main.async {
                self.cameraError = .cannotAddOutput
                self.showCameraAlert = true
            }
            completionHandler(false)
            return
        }
        
        // Commit the configuration before marking as configured
        session.commitConfiguration()
        print("Session configuration committed")
        
        isCaptureSessionConfigured = true
        completionHandler(true)
    }
    
    func capturePhoto(completion: @escaping (UIImage?, Error?) -> Void) {
        guard isCameraReady else {
            completion(nil, CameraError.cameraUnavailable)
            return
        }
        
        photoCaptureCompletionBlock = completion
        
        sessionQueue.async {
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            self.output.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func stopSession() {
        print("Stopping camera session")
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                print("Camera session stopped")
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletionBlock?(nil, error)
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            self.photo = image
            photoCaptureCompletionBlock?(image, nil)
        } else {
            photoCaptureCompletionBlock?(nil, CameraError.cameraUnavailable)
        }
    }
}
