import Foundation
import Combine

// MARK: - Property Service
@MainActor
class PropertyService: ObservableObject {
    static let shared = PropertyService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Property Management
    
    /// Get all properties for the current user
    func getAllProperties(completion: @escaping (Result<PropertiesResponse, NetworkError>) -> Void) {
        print("🏠 Fetching all properties...")
        
        // Validate token availability
        guard TokenManager.shared.hasValidToken() else {
            print("⚠️ No valid token available for properties API call")
            completion(.failure(.unauthorized))
            return
        }
        
        // Debug: Check if token is available
        print("🔑 Token available: \(TokenManager.shared.getAuthorizationHeader() != nil)")
        if let token = TokenManager.shared.getAuthorizationHeader() {
            print("🔑 Token preview: \(String(token.prefix(20)))...")
        } else {
            print("⚠️ No authorization token available for properties API call")
            completion(.failure(.unauthorized))
            return
        }
        
        // Create explicit authorization headers
        var headers: [String: String]? = nil
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            headers = ["Authorization": authHeader]
            print("🔑 Explicitly adding authorization header to properties request: \(String(authHeader.prefix(20)))...")
        }
        
        networkService.request<PropertiesResponse>(
            endpoint: .getAllProperties,
            method: .GET,
            body: nil,
            headers: headers
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Properties fetch completed")
                case .failure(let error):
                    print("❌ Properties fetch failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PropertiesResponse) in
                print("📥 Properties fetched: \(response.data?.count ?? 0) properties")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Create a new property
    func createProperty(
        name: String,
        type: String,
        street: String,
        city: String,
        state: String,
        zip: String,
        country: String,
        completion: @escaping (Result<PropertyResponse, NetworkError>) -> Void
    ) {
        print("🆕 Creating new property: \(name)")
        
        // Validate token availability
        guard TokenManager.shared.hasValidToken() else {
            print("⚠️ No valid token available for property creation")
            completion(.failure(.unauthorized))
            return
        }
        
        let request = CreatePropertyRequest(
            name: name,
            propertyType: type,
            street: street,
            city: city,
            state: state,
            zip: zip,
            country: country
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        // Create explicit authorization headers
        var headers: [String: String]? = nil
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            headers = ["Authorization": authHeader]
            print("🔑 Explicitly adding authorization header to property creation request")
        }
        
        networkService.request<PropertyResponse>(
            endpoint: .createProperty,
            method: .POST,
            body: requestData,
            headers: headers
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Property creation completed")
                case .failure(let error):
                    print("❌ Property creation failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PropertyResponse) in
                print("📥 Property created successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Get specific property by ID
    func getProperty(id: String, completion: @escaping (Result<PropertyResponse, NetworkError>) -> Void) {
        print("🔍 Fetching property: \(id)")
        
        // Validate token availability
        guard TokenManager.shared.hasValidToken() else {
            print("⚠️ No valid token available for property fetch")
            completion(.failure(.unauthorized))
            return
        }
        
        // Create explicit authorization headers
        var headers: [String: String]? = nil
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            headers = ["Authorization": authHeader]
            print("🔑 Explicitly adding authorization header to property fetch request")
        }
        
        networkService.request<PropertyResponse>(
            endpoint: .getProperty(id),
            method: .GET,
            body: nil,
            headers: headers
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Property fetch completed")
                case .failure(let error):
                    print("❌ Property fetch failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PropertyResponse) in
                print("📥 Property fetched successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Update existing property
    func updateProperty(
        id: String,
        name: String? = nil,
        type: String? = nil,
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        completion: @escaping (Result<PropertyResponse, NetworkError>) -> Void
    ) {
        print("✏️ Updating property: \(id)")
        
        // Validate token availability
        guard TokenManager.shared.hasValidToken() else {
            print("⚠️ No valid token available for property update")
            completion(.failure(.unauthorized))
            return
        }
        
        let request = UpdatePropertyRequest(
            name: name,
            propertyType: type,
            street: street,
            city: city,
            state: state,
            zip: zip,
            country: country
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        // Create explicit authorization headers
        var headers: [String: String]? = nil
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            headers = ["Authorization": authHeader]
            print("🔑 Explicitly adding authorization header to property update request")
        }
        
        networkService.request<PropertyResponse>(
            endpoint: .updateProperty(id),
            method: .PUT,
            body: requestData,
            headers: headers
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Property update completed")
                case .failure(let error):
                    print("❌ Property update failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: PropertyResponse) in
                print("📥 Property updated successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Delete property
    func deleteProperty(id: String, completion: @escaping (Result<DeleteResponse, NetworkError>) -> Void) {
        print("🗑️ Deleting property: \(id)")
        
        // Validate token availability
        guard TokenManager.shared.hasValidToken() else {
            print("⚠️ No valid token available for property deletion")
            completion(.failure(.unauthorized))
            return
        }
        
        // Create explicit authorization headers
        var headers: [String: String]? = nil
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            headers = ["Authorization": authHeader]
            print("🔑 Explicitly adding authorization header to property deletion request")
        }
        
        networkService.request<DeleteResponse>(
            endpoint: .deleteProperty(id),
            method: .DELETE,
            body: nil,
            headers: headers
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Property deletion completed")
                case .failure(let error):
                    print("❌ Property deletion failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: DeleteResponse) in
                print("📥 Property deleted successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Async/Await Methods
    
    @MainActor
    func getAllProperties() async throws -> PropertiesResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getAllProperties { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func createProperty(name: String, type: String, street: String, city: String, state: String, zip: String, country: String) async throws -> PropertyResponse {
        return try await withCheckedThrowingContinuation { continuation in
            createProperty(name: name, type: type, street: street, city: city, state: state, zip: zip, country: country) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func getProperty(id: String) async throws -> PropertyResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getProperty(id: id) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func updateProperty(id: String, name: String? = nil, type: String? = nil, street: String? = nil, city: String? = nil, state: String? = nil, zip: String? = nil, country: String? = nil) async throws -> PropertyResponse {
        return try await withCheckedThrowingContinuation { continuation in
            updateProperty(id: id, name: name, type: type, street: street, city: city, state: state, zip: zip, country: country) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func deleteProperty(id: String) async throws -> DeleteResponse {
        return try await withCheckedThrowingContinuation { continuation in
            deleteProperty(id: id) { result in
                continuation.resume(with: result)
            }
        }
    }
}
