import SwiftUI
import UIKit

// MARK: - Usage Example View
struct CloudinaryImageUploadView: View {
    @StateObject private var cloudinaryService = CloudinaryService()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var uploadedAssetId: String?
    @State private var uploadedPublicId: String?
    @State private var retrievedImage: UIImage?
    @State private var retrievedImageInfo: CloudinaryImageInfo?
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var getImageAssetId: String = ""
    @State private var getImagePublicId: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Upload Section
                    VStack(spacing: 15) {
                        Text("Upload Image")
                            .font(.headline)
                        
                        // Display selected image
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Select Image Button
                        Button("Select Image") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        // Upload Button
                        if selectedImage != nil {
                            Button("Upload Image") {
                                Task {
                                    await uploadImage()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(cloudinaryService.isUploading)
                        }
                        
                        // Upload Progress
                        if cloudinaryService.isUploading {
                            VStack {
                                Text("Uploading...")
                                ProgressView()
                            }
                        }
                        
                        // Upload Results
                        if let assetId = uploadedAssetId {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Upload Successful!")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                
                                Group {
                                    Text("Asset ID:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(assetId)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                    
                                    if let publicId = uploadedPublicId {
                                        Text("Public ID:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(publicId)
                                            .font(.caption)
                                            .textSelection(.enabled)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // MARK: - Get Image Section
                    VStack(spacing: 15) {
                        Text("Get Image")
                            .font(.headline)
                        
                        // Get by Asset ID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Get by Asset ID:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Asset ID", text: $getImageAssetId)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Get Image by Asset ID") {
                                Task {
                                    await getImageByAssetId()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(getImageAssetId.isEmpty || cloudinaryService.isGettingImage)
                        }
                        
                        // Get by Public ID
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Get by Public ID:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter Public ID (e.g., ekshakti/filename)", text: $getImagePublicId)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Get Image by Public ID") {
                                Task {
                                    await getImageByPublicId()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(getImagePublicId.isEmpty || cloudinaryService.isGettingImage)
                        }
                        
                        // Get Progress
                        if cloudinaryService.isGettingImage {
                            VStack {
                                Text("Fetching Image...")
                                ProgressView()
                            }
                        }
                        
                        // Retrieved Image Display
                        if let image = retrievedImage {
                            VStack(spacing: 10) {
                                Text("Retrieved Image:")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                if let info = retrievedImageInfo {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Image Info:")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Size: \(info.width) × \(info.height)")
                                        Text("Format: \(info.format.uppercased())")
                                        Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(info.bytes), countStyle: .file))")
                                        Text("Created: \(formatDate(info.createdAt))")
                                    }
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // MARK: - Delete Section
                    if uploadedAssetId != nil {
                        VStack(spacing: 15) {
                            Text("Delete Image")
                                .font(.headline)
                            
                            Button("Delete Uploaded Image") {
                                Task {
                                    await deleteImage()
                                }
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .disabled(cloudinaryService.isDeleting)
                            
                            // Delete Progress
                            if cloudinaryService.isDeleting {
                                VStack {
                                    Text("Deleting...")
                                    ProgressView()
                                }
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Cloudinary Upload")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
    }
    
    private func uploadImage() async {
        guard let image = selectedImage else { return }
        
        do {
            let response = try await cloudinaryService.uploadImage(image)
            uploadedAssetId = response.assetId
            uploadedPublicId = response.publicId
            print("Upload successful! Asset ID: \(response.assetId)")
            print("Public ID: \(response.publicId)")
            print("URL: \(response.secureUrl)")
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
            print("Upload failed: \(error)")
        }
    }
    
    private func getImageByAssetId() async {
        do {
            let imageData = try await cloudinaryService.getImage(assetId: getImageAssetId)
            retrievedImage = imageData.image
            retrievedImageInfo = imageData.imageInfo
            print("Get image successful! Asset ID: \(imageData.imageInfo.assetId)")
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
            print("Get image failed: \(error)")
        }
    }
    
    private func getImageByPublicId() async {
        do {
            let imageData = try await cloudinaryService.getImage(publicId: getImagePublicId)
            retrievedImage = imageData.image
            retrievedImageInfo = imageData.imageInfo
            print("Get image successful! Public ID: \(imageData.imageInfo.publicId)")
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
            print("Get image failed: \(error)")
        }
    }
    
    private func deleteImage() async {
        guard let assetId = uploadedAssetId else { return }
        
        do {
            let response = try await cloudinaryService.deleteImage(assetId: assetId)
            print("Delete successful: \(response)")
            
            // Reset state after successful deletion
            uploadedAssetId = nil
            uploadedPublicId = nil
            selectedImage = nil
            retrievedImage = nil
            retrievedImageInfo = nil
            
        } catch {
            errorMessage = error.localizedDescription
            showingAlert = true
            print("Delete failed: \(error)")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
 
