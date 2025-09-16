import Foundation
import Combine

// MARK: - Room Service
@MainActor
class RoomService: ObservableObject {
    static let shared = RoomService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Room Management
    
    /// Create a new room in a property
    func createRoom(
        propertyId: String,
        name: String,
        type: String,
        completion: @escaping (Result<RoomResponse, NetworkError>) -> Void
    ) {
        print("🆕 Creating new room: \(name) in property: \(propertyId)")
        
        let request = CreateRoomRequest(name: name, type: type)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        let publisher: AnyPublisher<RoomResponse, NetworkError> = networkService.request(
            endpoint: .createRoom(propertyId),
            method: .POST,
            body: requestData,
            headers: nil
        )
        
        publisher.sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Room creation completed")
                case .failure(let error):
                    print("❌ Room creation failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { response in
                print("📥 Room created successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Get all rooms in a property
    func getRoomsInProperty(propertyId: String, completion: @escaping (Result<RoomsResponse, NetworkError>) -> Void) {
        print("🏠 Fetching rooms in property: \(propertyId)")
        
        let publisher: AnyPublisher<RoomsResponse, NetworkError> = networkService.request(
            endpoint: .getRoomsInProperty(propertyId),
            method: .GET,
            body: nil,
            headers: nil
        )
        
        publisher.sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Rooms fetch completed")
                case .failure(let error):
                    print("❌ Rooms fetch failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { response in
                print("📥 Rooms fetched: \(response.data?.count ?? 0) rooms")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Get specific room by ID
    func getRoom(id: String, completion: @escaping (Result<RoomResponse, NetworkError>) -> Void) {
        print("🔍 Fetching room: \(id)")
        
        let publisher: AnyPublisher<RoomResponse, NetworkError> = networkService.request(
            endpoint: .getRoom(id),
            method: .GET,
            body: nil,
            headers: nil
        )
        
        publisher.sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Room fetch completed")
                case .failure(let error):
                    print("❌ Room fetch failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { response in
                print("📥 Room fetched successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Update existing room
    func updateRoom(
        id: String,
        name: String? = nil,
        type: String? = nil,
        completion: @escaping (Result<RoomResponse, NetworkError>) -> Void
    ) {
        print("✏️ Updating room: \(id)")
        
        let request = UpdateRoomRequest(name: name, type: type)
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        let publisher: AnyPublisher<RoomResponse, NetworkError> = networkService.request(
            endpoint: .updateRoom(id),
            method: .PUT,
            body: requestData,
            headers: nil
        )
        
        publisher.sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Room update completed")
                case .failure(let error):
                    print("❌ Room update failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { response in
                print("📥 Room updated successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Async/Await Methods
    
    @MainActor
    func createRoom(propertyId: String, name: String, type: String) async throws -> RoomResponse {
        return try await withCheckedThrowingContinuation { continuation in
            createRoom(propertyId: propertyId, name: name, type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func getRoomsInProperty(propertyId: String) async throws -> RoomsResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getRoomsInProperty(propertyId: propertyId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func getRoom(id: String) async throws -> RoomResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getRoom(id: id) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func updateRoom(id: String, name: String? = nil, type: String? = nil) async throws -> RoomResponse {
        return try await withCheckedThrowingContinuation { continuation in
            updateRoom(id: id, name: name, type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}
