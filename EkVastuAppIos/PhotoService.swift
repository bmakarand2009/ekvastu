import Foundation
import Combine

// MARK: - Photo Service
class PhotoService: ObservableObject {
    static let shared = PhotoService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Photo Management
    
    /// Add photo with cloud name and asset ID
    func addPhotoWithURL(
        roomId: String,
        cloudName: String,
        uri: String,
        completion: @escaping (Result<PhotoResponse, NetworkError>) -> Void
    ) {
        print("📸 Adding photo to room: \(roomId)")
        print("   - Cloud Name: \(cloudName)")
        print("   - URI: \(uri)")
        
        let request = CreatePhotoRequest(cloudName: cloudName, uri: uri)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        // Use special endpoint for URL-based photo addition
        let endpoint: APIEndpoint = .addPhotoWithURL(roomId)
        
        networkService.request<PhotoResponse>(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Photo addition completed")
                case .failure(let error):
                    print("❌ Photo addition failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PhotoResponse) in
                print("📥 Photo added successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Get all photos in a room
    func getPhotosInRoom(roomId: String, completion: @escaping (Result<PhotosResponse, NetworkError>) -> Void) {
        print("📷 Fetching photos in room: \(roomId)")
        
        networkService.request<PhotosResponse>(
            endpoint: .getPhotosInRoom(roomId),
            method: .GET,
            body: nil,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Photos fetch completed")
                case .failure(let error):
                    print("❌ Photos fetch failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PhotosResponse) in
                print("📥 Photos fetched: \(response.data?.count ?? 0) photos")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Delete photo
    func deletePhoto(id: String, completion: @escaping (Result<DeleteResponse, NetworkError>) -> Void) {
        print("🗑️ Deleting photo: \(id)")
        
        networkService.request<DeleteResponse>(
            endpoint: .deletePhoto(id),
            method: .DELETE,
            body: nil,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Photo deletion completed")
                case .failure(let error):
                    print("❌ Photo deletion failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: DeleteResponse) in
                print("📥 Photo deleted successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Async/Await Methods
    
    @MainActor
    func addPhotoWithURL(roomId: String, cloudName: String, uri: String) async throws -> PhotoResponse {
        return try await withCheckedThrowingContinuation { continuation in
            addPhotoWithURL(roomId: roomId, cloudName: cloudName, uri: uri) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func getPhotosInRoom(roomId: String) async throws -> PhotosResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getPhotosInRoom(roomId: roomId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func deletePhoto(id: String) async throws -> DeleteResponse {
        return try await withCheckedThrowingContinuation { continuation in
            deletePhoto(id: id) { result in
                continuation.resume(with: result)
            }
        }
    }
}
