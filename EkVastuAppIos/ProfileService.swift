import Foundation
import Combine

// MARK: - Profile Service
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Profile Management
    
    /// Check if profile exists for the current user
    func checkProfile(completion: @escaping (Result<ProfileResponse, NetworkError>) -> Void) {
        print("🔍 Checking if profile exists...")
        
        networkService.request<ProfileResponse>(
            endpoint: .checkProfile,
            method: .GET,
            body: nil,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Profile check completed")
                case .failure(let error):
                    print("❌ Profile check failed: \(error)")
                    
                    // Special handling for 404 responses with JSON error messages
                    if case .serverError(let statusCode, let errorMessage) = error,
                       statusCode == 404,
                       let errorMessage = errorMessage,
                       let errorData = errorMessage.data(using: .utf8) {
                        
                        // Try to parse the JSON error response
                        do {
                            let errorResponse = try JSONDecoder().decode(ProfileResponse.self, from: errorData)
                            print("📥 Parsed 404 error response: \(errorResponse.message ?? "Unknown")")
                            completion(.success(errorResponse))
                            return
                        } catch {
                            print("❌ Failed to parse 404 error response: \(error)")
                        }
                    }
                    
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: ProfileResponse) in
                print("📥 Profile check response: \(response.success)")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Create a new profile
    func createProfile(
        dob: String,
        placeOfBirth: String,
        timeOfBirth: String,
        completion: @escaping (Result<ProfileResponse, NetworkError>) -> Void
    ) {
        print("🆕 Creating new profile...")
        
        let request = CreateProfileRequest(
            dob: dob,
            placeOfBirth: placeOfBirth,
            timeOfBirth: timeOfBirth
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        networkService.request<ProfileResponse>(
            endpoint: .createProfile,
            method: .POST,
            body: requestData,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Profile creation completed")
                case .failure(let error):
                    print("❌ Profile creation failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: ProfileResponse) in
                print("📥 Profile created successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    /// Update existing profile
    func updateProfile(
        placeOfBirth: String? = nil,
        timeOfBirth: String? = nil,
        completion: @escaping (Result<ProfileResponse, NetworkError>) -> Void
    ) {
        print("✏️ Updating profile...")
        
        let request = UpdateProfileRequest(
            placeOfBirth: placeOfBirth,
            timeOfBirth: timeOfBirth
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            completion(.failure(.invalidRequest))
            return
        }
        
        networkService.request<ProfileResponse>(
            endpoint: .updateProfile,
            method: .PUT,
            body: requestData,
            headers: nil
        )
        .sink(
            receiveCompletion: { completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Profile update completed")
                case .failure(let error):
                    print("❌ Profile update failed: \(error)")
                    completion(.failure(error))
                }
            },
            receiveValue: { (response: ProfileResponse) in
                print("📥 Profile updated successfully")
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Async/Await Methods
    
    @MainActor
    func checkProfile() async throws -> ProfileResponse {
        return try await withCheckedThrowingContinuation { continuation in
            checkProfile { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func createProfile(dob: String, placeOfBirth: String, timeOfBirth: String) async throws -> ProfileResponse {
        return try await withCheckedThrowingContinuation { continuation in
            createProfile(dob: dob, placeOfBirth: placeOfBirth, timeOfBirth: timeOfBirth) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    @MainActor
    func updateProfile(placeOfBirth: String? = nil, timeOfBirth: String? = nil) async throws -> ProfileResponse {
        return try await withCheckedThrowingContinuation { continuation in
            updateProfile(placeOfBirth: placeOfBirth, timeOfBirth: timeOfBirth) { result in
                continuation.resume(with: result)
            }
        }
    }
}
