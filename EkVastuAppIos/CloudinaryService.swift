import Foundation
import UIKit

// MARK: - Configuration Manager
struct ConfigManager {
    private static var config: [String: Any]? = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            print("⚠️ Config.plist not found - make sure to create Config.plist from Config-template.plist")
            return nil
        }
        return plist as? [String: Any]
    }()
    
    static func getValue(for key: String) -> String {
        guard let value = config?[key] as? String, !value.isEmpty else {
            print("⚠️ Missing or empty value for key: \(key)")
            return ""
        }
        return value
    }
    
    static var cloudinaryAPIKey: String {
        return getValue(for: "CLOUDINARY_API_KEY")
    }
    
    static var cloudinaryAPISecret: String {
        return getValue(for: "CLOUDINARY_API_SECRET")
    }
    
    static var cloudinaryCloudName: String {
        return getValue(for: "CLOUDINARY_CLOUD_NAME")
    }
}

// MARK: - Cloudinary Response Models
struct CloudinaryUploadResponse: Codable {
    let assetId: String
    let publicId: String
    let version: Int
    let versionId: String
    let signature: String
    let width: Int
    let height: Int
    let format: String
    let resourceType: String
    let createdAt: String
    let bytes: Int
    let type: String
    let url: String
    let secureUrl: String
    
    enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case publicId = "public_id"
        case version
        case versionId = "version_id"
        case signature
        case width
        case height
        case format
        case resourceType = "resource_type"
        case createdAt = "created_at"
        case bytes
        case type
        case url
        case secureUrl = "secure_url"
    }
}

struct CloudinaryDeleteResponse: Codable {
    let deleted: [String: String]
    let deletedCounts: DeletedCounts
    let partial: Bool
    let rateLimitAllowed: Int
    let rateLimitResetAt: String
    let rateLimitRemaining: Int
    
    enum CodingKeys: String, CodingKey {
        case deleted
        case deletedCounts = "deleted_counts"
        case partial
        case rateLimitAllowed = "rate_limit_allowed"
        case rateLimitResetAt = "rate_limit_reset_at"
        case rateLimitRemaining = "rate_limit_remaining"
    }
}

struct DeletedCounts: Codable {
    let original: Int
    let derived: Int
}

// MARK: - Simplified CloudinaryImageInfo (Manual Parsing Only)
struct CloudinaryImageInfo {
    let assetId: String
    let publicId: String
    let version: Int
    let format: String
    let resourceType: String
    let createdAt: String
    let bytes: Int
    let type: String
    let url: String
    let secureUrl: String
    let width: Int
    let height: Int
    let backup: Bool?
    let folder: String?
    let nextCursor: String?
    let versionId: String?
    let signature: String?
    let uploadedAt: String?
    let originalFilename: String?
    
    // Custom initializer from JSON dictionary - NO CODABLE
    init(from jsonResponse: [String: Any]) {
        self.assetId = jsonResponse["asset_id"] as? String ?? ""
        self.publicId = jsonResponse["public_id"] as? String ?? ""
        self.version = jsonResponse["version"] as? Int ?? 0
        self.format = jsonResponse["format"] as? String ?? "jpg"
        self.resourceType = jsonResponse["resource_type"] as? String ?? "image"
        self.createdAt = jsonResponse["created_at"] as? String ?? ""
        self.bytes = jsonResponse["bytes"] as? Int ?? 0
        self.type = jsonResponse["type"] as? String ?? "upload"
        self.url = jsonResponse["url"] as? String ?? ""
        self.secureUrl = jsonResponse["secure_url"] as? String ?? ""
        self.width = jsonResponse["width"] as? Int ?? 0
        self.height = jsonResponse["height"] as? Int ?? 0
        self.backup = jsonResponse["backup"] as? Bool
        self.folder = jsonResponse["folder"] as? String
        self.nextCursor = jsonResponse["next_cursor"] as? String
        self.versionId = jsonResponse["version_id"] as? String
        self.signature = jsonResponse["signature"] as? String
        self.uploadedAt = jsonResponse["uploaded_at"] as? String
        self.originalFilename = jsonResponse["original_filename"] as? String
    }
}

struct CloudinaryImageData {
    let imageInfo: CloudinaryImageInfo
    let image: UIImage
}

// MARK: - Custom Errors
enum CloudinaryError: Error, LocalizedError {
    case invalidImage
    case uploadFailed(String)
    case deleteFailed(String)
    case getFailed(String)
    case imageNotFound
    case networkError(Error)
    case invalidResponse
    case missingAssetId
    case missingPublicId
    case missingConfiguration
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .getFailed(let message):
            return "Get image failed: \(message)"
        case .imageNotFound:
            return "Image not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .missingAssetId:
            return "Asset ID is required for deletion"
        case .missingPublicId:
            return "Public ID is required to get image"
        case .missingConfiguration:
            return "Missing Cloudinary configuration. Please check Config.plist file."
        }
    }
}

// MARK: - Cloudinary Service
@MainActor
class CloudinaryService: ObservableObject {
    
    // MARK: - Configuration Manager
    private let tenantConfig = TenantConfigManager.shared
    
    // MARK: - API Credentials (Loaded from Config.plist)
    private let apiKey: String
    private let apiSecret: String
    
    // MARK: - Dynamic Configuration Properties
    private var cloudName: String {
        return tenantConfig.cloudinaryCloudName
    }
    
    private var uploadPreset: String {
        return tenantConfig.cloudinaryUploadPreset
    }
    
    private var folder: String {
        return tenantConfig.cloudinaryFolder
    }
    
    // MARK: - Properties
    @Published var isUploading = false
    @Published var isDeleting = false
    @Published var isGettingImage = false
    @Published var uploadProgress: Double = 0.0
    
    private let session = URLSession.shared
    
    // MARK: - Initialization
    init() {
        self.apiKey = ConfigManager.cloudinaryAPIKey
        self.apiSecret = ConfigManager.cloudinaryAPISecret
        
        // Validate static configuration on initialization
        if apiKey.isEmpty || apiSecret.isEmpty {
            print("⚠️ Cloudinary static configuration is incomplete:")
            print("   - API Key: \(apiKey.isEmpty ? "MISSING" : "✓")")
            print("   - API Secret: \(apiSecret.isEmpty ? "MISSING" : "✓")")
            print("   Please check your Config.plist file")
        }
        
        print("🔧 CloudinaryService initialized with dynamic tenant configuration")
    }
    
    // MARK: - Configuration Validation
    private func validateConfiguration() throws {
        let currentCloudName = cloudName
        let currentUploadPreset = uploadPreset
        let currentFolder = folder
        
        guard !currentCloudName.isEmpty && !apiKey.isEmpty && !apiSecret.isEmpty else {
            print("❌ Cloudinary configuration validation failed:")
            print("   - Cloud Name: \(currentCloudName.isEmpty ? "MISSING" : currentCloudName)")
            print("   - Upload Preset: \(currentUploadPreset.isEmpty ? "MISSING" : currentUploadPreset)")
            print("   - Folder: \(currentFolder.isEmpty ? "MISSING" : currentFolder)")
            print("   - API Key: \(apiKey.isEmpty ? "MISSING" : "✓")")
            print("   - API Secret: \(apiSecret.isEmpty ? "MISSING" : "✓")")
            throw CloudinaryError.missingConfiguration
        }
        
        print("✅ Cloudinary configuration validated:")
        print("   - Cloud Name: \(currentCloudName)")
        print("   - Upload Preset: \(currentUploadPreset)")
        print("   - Folder: \(currentFolder)")
    }
    
    // MARK: - Upload Image
    func uploadImage(_ image: UIImage) async throws -> CloudinaryUploadResponse {
        // Ensure tenant config is available before upload
        await ensureTenantConfigLoaded()
        
        try validateConfiguration()
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CloudinaryError.invalidImage
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            let response = try await performUpload(imageData: imageData)
            return response
        } catch {
            if let cloudinaryError = error as? CloudinaryError {
                throw cloudinaryError
            } else {
                throw CloudinaryError.networkError(error)
            }
        }
    }
    
    // MARK: - Ensure Tenant Config is Loaded
    private func ensureTenantConfigLoaded() async {
        // If tenant config is not loaded, try to load it
        if !tenantConfig.isConfigLoaded {
            print("⚠️ CloudinaryService: Tenant config not loaded, attempting to load...")
            
            do {
                let authService = AuthService.shared
                let _ = try await authService.getTenantInfo()
                print("✅ CloudinaryService: Tenant config loaded successfully")
            } catch {
                print("❌ CloudinaryService: Failed to load tenant config: \(error.localizedDescription)")
                print("   Will use fallback configuration")
            }
        } else {
            print("✅ CloudinaryService: Tenant config already loaded")
        }
        
        // Print current configuration for debugging
        tenantConfig.printCurrentConfig()
    }
    
    // MARK: - Delete Image by Asset ID
    func deleteImage(assetId: String) async throws -> CloudinaryDeleteResponse {
        try validateConfiguration()
        
        guard !assetId.isEmpty else {
            throw CloudinaryError.missingAssetId
        }
        
        isDeleting = true
        
        defer {
            isDeleting = false
        }
        
        do {
            let response = try await performDelete(assetId: assetId)
            return response
        } catch {
            if let cloudinaryError = error as? CloudinaryError {
                throw cloudinaryError
            } else {
                throw CloudinaryError.networkError(error)
            }
        }
    }
    
    // MARK: - Delete Image by URL
    func deleteWithUrl(url: String) async throws -> CloudinaryDeleteResponse {
        try validateConfiguration()
        guard let publicId = extractPublicId(from: url), !publicId.isEmpty else {
            throw CloudinaryError.missingPublicId
        }
        return try await deleteByPublicId(publicId: publicId)
    }
    
    private func extractPublicId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        var path = url.path
        path = path.removingPercentEncoding ?? path
        // Expect path like: /image/upload/v12345/folder/name.ext (with optional version)
        guard let uploadRange = path.range(of: "/upload/") else { return nil }
        var after = String(path[uploadRange.upperBound...])
        var segments = after.split(separator: "/").map(String.init)
        // Drop version segment if present (v + digits)
        if let first = segments.first, first.hasPrefix("v"), Int(first.dropFirst()) != nil {
            segments.removeFirst()
        }
        guard !segments.isEmpty else { return nil }
        // Remove file extension from last segment
        if var last = segments.last, let dot = last.lastIndex(of: ".") {
            last = String(last[..<dot])
            segments[segments.count - 1] = last
        }
        let publicId = segments.joined(separator: "/")
        return publicId.isEmpty ? nil : publicId
    }
    
    // MARK: - Delete Image by Public ID
    func deleteByPublicId(publicId: String) async throws -> CloudinaryDeleteResponse {
        try validateConfiguration()
        guard !publicId.isEmpty else { throw CloudinaryError.missingPublicId }
        isDeleting = true
        defer { isDeleting = false }
        return try await performDeleteByPublicIds(publicIds: [publicId])
    }
    
    // MARK: - Get Image Info by Asset ID
    func getImageInfo(assetId: String) async throws -> CloudinaryImageInfo {
        try validateConfiguration()
        
        guard !assetId.isEmpty else {
            throw CloudinaryError.missingAssetId
        }
        
        isGettingImage = true
        
        defer {
            isGettingImage = false
        }
        
        do {
            let response = try await performGetImageInfo(assetId: assetId)
            return response
        } catch {
            if let cloudinaryError = error as? CloudinaryError {
                throw cloudinaryError
            } else {
                throw CloudinaryError.networkError(error)
            }
        }
    }
    
    // MARK: - Get Image Info by Public ID
    func getImageInfo(publicId: String) async throws -> CloudinaryImageInfo {
        try validateConfiguration()
        
        guard !publicId.isEmpty else {
            throw CloudinaryError.missingPublicId
        }
        
        isGettingImage = true
        
        defer {
            isGettingImage = false
        }
        
        do {
            let response = try await performGetImageInfoByPublicId(publicId: publicId)
            return response
        } catch {
            if let cloudinaryError = error as? CloudinaryError {
                throw cloudinaryError
            } else {
                throw CloudinaryError.networkError(error)
            }
        }
    }
    
    // MARK: - Get Image Data by Asset ID
    func getImage(assetId: String) async throws -> CloudinaryImageData {
        let imageInfo = try await getImageInfo(assetId: assetId)
        let image = try await downloadImage(from: imageInfo.secureUrl)
        
        return CloudinaryImageData(imageInfo: imageInfo, image: image)
    }
    
    // MARK: - Get Image Data by Public ID
    func getImage(publicId: String) async throws -> CloudinaryImageData {
        let imageInfo = try await getImageInfo(publicId: publicId)
        let image = try await downloadImage(from: imageInfo.secureUrl)
        
        return CloudinaryImageData(imageInfo: imageInfo, image: image)
    }
    
    // MARK: - Get Image by URL (for direct URL access)
    func getImage(from url: String) async throws -> UIImage {
        return try await downloadImage(from: url)
    }
    
    // MARK: - Private Methods
    
    private func performUpload(imageData: Data) async throws -> CloudinaryUploadResponse {
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add Basic Authentication for signed presets
        let credentials = "\(apiKey):\(apiSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            print("🔐 Adding authentication for signed upload preset")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartBody(
            imageData: imageData,
            boundary: boundary,
            preset: uploadPreset,
            folder: folder
        )
        
        request.httpBody = httpBody
        
        print("🌐 Making direct POST request to: \(url.absoluteString)")
        
        // Print curl command for debugging
        NetworkService.shared.printCurlCommand(for: request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw CloudinaryError.uploadFailed(message)
            } else {
                throw CloudinaryError.uploadFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        do {
            let uploadResponse = try JSONDecoder().decode(CloudinaryUploadResponse.self, from: data)
            return uploadResponse
        } catch {
            print("JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            throw CloudinaryError.invalidResponse
        }
    }
    
    private func performDelete(assetId: String) async throws -> CloudinaryDeleteResponse {
        // Correct endpoint for deleting by asset_ids
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/resources/image/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add Basic Authentication
        let credentials = "\(apiKey):\(apiSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        // Use asset_ids array as per API specification
        let deleteBody: [String: Any] = [
            "asset_ids": [assetId]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: deleteBody)
        
        print("🌐 Making direct DELETE request to: \(url.absoluteString)")
        
        // Print curl command for debugging
        NetworkService.shared.printCurlCommand(for: request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw CloudinaryError.deleteFailed("Invalid API credentials. Please check your API key and secret in Config.plist.")
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw CloudinaryError.deleteFailed(message)
            } else {
                throw CloudinaryError.deleteFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Handle the actual delete response structure
        do {
            let deleteResponse = try JSONDecoder().decode(CloudinaryDeleteResponse.self, from: data)
            return deleteResponse
        } catch {
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Delete response JSON: \(jsonResponse)")
                let simpleResponse = CloudinaryDeleteResponse(
                    deleted: [assetId: "deleted"],
                    deletedCounts: DeletedCounts(original: 1, derived: 0),
                    partial: false,
                    rateLimitAllowed: 500,
                    rateLimitResetAt: "",
                    rateLimitRemaining: 499
                )
                return simpleResponse
            } else {
                print("JSON Decode Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }
                throw CloudinaryError.invalidResponse
            }
        }
    }
    
    private func performDeleteByPublicIds(publicIds: [String]) async throws -> CloudinaryDeleteResponse {
        // Endpoint for deleting by public_ids
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/resources/image/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(apiKey):\(apiSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let deleteBody: [String: Any] = [
            "public_ids": publicIds
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: deleteBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw CloudinaryError.deleteFailed("Invalid API credentials. Please check your API key and secret in Config.plist.")
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw CloudinaryError.deleteFailed(message)
            } else {
                throw CloudinaryError.deleteFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        do {
            let deleteResponse = try JSONDecoder().decode(CloudinaryDeleteResponse.self, from: data)
            return deleteResponse
        } catch {
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Delete response JSON: \(jsonResponse)")
                var deletedMap: [String: String] = [:]
                publicIds.forEach { deletedMap[$0] = "deleted" }
                let simpleResponse = CloudinaryDeleteResponse(
                    deleted: deletedMap,
                    deletedCounts: DeletedCounts(original: publicIds.count, derived: 0),
                    partial: false,
                    rateLimitAllowed: 500,
                    rateLimitResetAt: "",
                    rateLimitRemaining: 499
                )
                return simpleResponse
            } else {
                print("JSON Decode Error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }
                throw CloudinaryError.invalidResponse
            }
        }
    }
    
    private func performGetImageInfo(assetId: String) async throws -> CloudinaryImageInfo {
        print("🔍 Getting image info for asset_id: \(assetId)")
        
        // Try search endpoint which is known to work
        let searchUrl = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/resources/image/upload")!
        var components = URLComponents(url: searchUrl, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "asset_ids", value: assetId)]
        
        guard let finalUrl = components.url else {
            throw CloudinaryError.invalidResponse
        }
        
        var request = URLRequest(url: finalUrl)
        request.httpMethod = "GET"
        
        // Add Basic Authentication
        let credentials = "\(apiKey):\(apiSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        print("🔍 Trying search endpoint: \(finalUrl.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw CloudinaryError.getFailed("Invalid API credentials. Please check your API key and secret in Config.plist.")
        }
        
        if httpResponse.statusCode == 404 {
            throw CloudinaryError.imageNotFound
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw CloudinaryError.getFailed(message)
            } else {
                throw CloudinaryError.getFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Response JSON: \(String(jsonString.prefix(300)))...")
        }
        
        // Parse search response manually
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resources = jsonResponse["resources"] as? [[String: Any]],
           let firstResource = resources.first {
            
            print("✅ Found resource in search results")
            let imageInfo = CloudinaryImageInfo(from: firstResource)
            return imageInfo
        } else {
            print("❌ No resources found in search response")
            throw CloudinaryError.imageNotFound
        }
    }
    
    private func performGetImageInfoByPublicId(publicId: String) async throws -> CloudinaryImageInfo {
        // Clean the public ID - remove any version numbers, file extensions, or extra URL parts
        var cleanPublicId = publicId
        
        // If it looks like a full URL, extract just the public_id part
        if cleanPublicId.contains("cloudinary.com") {
            let components = cleanPublicId.components(separatedBy: "/")
            if let uploadIndex = components.firstIndex(of: "upload"),
               uploadIndex + 1 < components.count {
                let pathComponents = Array(components[(uploadIndex + 1)...])
                cleanPublicId = pathComponents.joined(separator: "/")
            }
        }
        
        // Remove version number if present (starts with 'v' followed by digits)
        if let versionRange = cleanPublicId.range(of: #"^v\d+/"#, options: .regularExpression) {
            cleanPublicId = String(cleanPublicId[versionRange.upperBound...])
        }
        
        // Remove file extension
        if let lastDot = cleanPublicId.lastIndex(of: ".") {
            cleanPublicId = String(cleanPublicId[..<lastDot])
        }
        
        print("🔧 Original public_id: \(publicId)")
        print("🔧 Cleaned public_id: \(cleanPublicId)")
        
        // URL encode the public ID to handle special characters and folder paths
        guard let encodedPublicId = cleanPublicId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw CloudinaryError.invalidResponse
        }
        
        print("🔧 Encoded public_id: \(encodedPublicId)")
        
        // Correct endpoint for getting single resource by public_id
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/resources/image/upload/\(encodedPublicId)")!
        
        print("🔍 Trying endpoint: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add Basic Authentication
        let credentials = "\(apiKey):\(apiSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudinaryError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw CloudinaryError.getFailed("Invalid API credentials. Please check your API key and secret in Config.plist.")
        }
        
        if httpResponse.statusCode == 404 {
            print("❌ Resource not found for public_id: \(cleanPublicId)")
            throw CloudinaryError.imageNotFound
        }
        
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                print("🚨 API Error: \(message)")
                throw CloudinaryError.getFailed(message)
            } else {
                print("🚨 HTTP Error: \(httpResponse.statusCode)")
                throw CloudinaryError.getFailed("HTTP \(httpResponse.statusCode)")
            }
        }
        
        print("✅ Successfully retrieved resource data")
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Response JSON: \(String(jsonString.prefix(300)))...")
        }
        
        // Always use manual parsing to avoid JSONDecoder issues
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✅ Successfully parsed JSON response manually")
            let imageInfo = CloudinaryImageInfo(from: jsonResponse)
            return imageInfo
        } else {
            print("❌ Could not parse JSON response")
            throw CloudinaryError.invalidResponse
        }
    }
    
    private func createMultipartBody(imageData: Data, boundary: String, preset: String, folder: String) -> Data {
        var body = Data()
        
        print("📤 CloudinaryService: Creating multipart body")
        print("   - Upload Preset: \(preset)")
        print("   - Folder: \(folder)")
        print("   - API Key: \(apiKey)")
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(preset)\r\n".data(using: .utf8)!)
        
        // Add API key for signed presets
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"api_key\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiKey)\r\n".data(using: .utf8)!)
        
        // Add timestamp for signed presets
        let timestamp = Int(Date().timeIntervalSince1970)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(timestamp)\r\n".data(using: .utf8)!)
        
        // Add folder
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(folder)\r\n".data(using: .utf8)!)
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw CloudinaryError.invalidResponse
        }
        
        print("🌐 Making direct GET request to: \(url.absoluteString)")
        
        let request = URLRequest(url: url)
        
        // Print curl command for debugging
        NetworkService.shared.printCurlCommand(for: request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CloudinaryError.imageNotFound
        }
        
        guard let image = UIImage(data: data) else {
            throw CloudinaryError.invalidImage
        }
        
        return image
    }
}

