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
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized {
                    self.cameraError = .deniedAuthorization
                    self.showCameraAlert = true
                }
                self.sessionQueue.resume()
            }
        case .restricted:
            cameraError = .restrictedAuthorization
            showCameraAlert = true
        case .denied:
            cameraError = .deniedAuthorization
            showCameraAlert = true
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    func setupAndStartCaptureSession() {
        checkPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession { success in
                guard success else { return }
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
            }
        }
    }
    
    func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        guard !isCaptureSessionConfigured else { return completionHandler(true) }
        
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        guard let camera = videoDevice else {
            cameraError = .cameraUnavailable
            showCameraAlert = true
            completionHandler(false)
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                cameraError = .cannotAddInput
                showCameraAlert = true
                completionHandler(false)
                return
            }
        } catch {
            cameraError = .createCaptureInput(error)
            showCameraAlert = true
            completionHandler(false)
            return
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.isHighResolutionCaptureEnabled = true
            output.maxPhotoQualityPrioritization = .quality
        } else {
            cameraError = .cannotAddOutput
            showCameraAlert = true
            completionHandler(false)
            return
        }
        
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
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
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
