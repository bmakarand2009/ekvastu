import Foundation
import Combine

// MARK: - Profile Service
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Helpers
    /// Detects common JWT/auth related error responses coming from the backend and clears tokens if needed.
    /// Returns true if it handled an authentication error (tokens cleared and caller should treat as unauthorized).
    private func handleAuthErrorIfNeeded(_ data: Data) -> Bool {
        guard let responseString = String(data: data, encoding: .utf8) else { return false }
        
        // Direct string checks
        let lower = responseString.lowercased()
        let jwtSignatureFailed = lower.contains("signature verification failed") ||
                                 (lower.contains("jwt") && lower.contains("signature") && lower.contains("failed"))
        let jwtSegmentsError = responseString.contains("Not enough or too many segments")
        
        var isAuthError = jwtSignatureFailed || jwtSegmentsError
        
        // Try to parse nested error JSON like {"errors":{"message":"Signature verification failed"}}
        if !isAuthError, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let errors = json["errors"] as? [String: Any],
               let message = errors["message"] as? String,
               message.lowercased().contains("signature verification failed") {
                isAuthError = true
            }
        }
        
        if isAuthError {
            print("⚠️ JWT token error detected - token may be invalid or expired. Clearing tokens and forcing re-auth.")
            // Clear tokens and let the UI handle re-authentication flow
            Task { @MainActor in
                TokenManager.shared.clearTokens()
            }
            return true
        }
        
        return false
    }
    
    /// Detects HTML responses (e.g., server login page) which indicate an unauthorized session in this context
    private func isHTMLResponse(_ httpResponse: HTTPURLResponse, data: Data) -> Bool {
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased() ?? ""
        if contentType.contains("text/html") { return true }
        if let text = String(data: data, encoding: .utf8) {
            let lower = text.lowercased()
            if lower.contains("<!doctype html") || lower.contains("<html") { return true }
        }
        return false
    }
    
    // MARK: - Profile Management
    
    /// Check if profile exists for the current user
    func checkProfile(completion: @escaping (Result<ProfileResponse, NetworkError>) -> Void) {
        print("🔍 Checking if profile exists...")
        
        // Use direct URL request instead of the generic request method
        let url = URL(string: APIConfig.ekshaktiBaseURL + "/profile")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header if available
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No authentication token available for profile check")
            completion(.failure(.unauthorized))
            return
        }
        
        print("🌐 Making direct GET request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profile check network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    completion(.failure(.noData))
                    return
                }
                
                // If server returned an HTML page (login page), treat as unauthorized
                if let self = self, self.isHTMLResponse(httpResponse, data: data) {
                    Task { @MainActor in
                        TokenManager.shared.clearTokens()
                    }
                    completion(.failure(.unauthorized))
                    return
                }
                
                // Special handling for 404 responses (profile not found)
                if httpResponse.statusCode == 404 {
                    do {
                        let errorResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
                        print("📥 Parsed 404 response: \(errorResponse.message ?? "Unknown")")
                        completion(.success(errorResponse))
                        return
                    } catch {
                        print("❌ Failed to parse 404 response: \(error)")
                    }
                }
                
                // Try to extract error message if status code is not successful
                if httpResponse.statusCode >= 400 {
                    // Handle invalid/expired tokens consistently
                    if self?.handleAuthErrorIfNeeded(data) == true {
                        completion(.failure(.unauthorized))
                        return
                    }
                    
                    // Handle other errors
                    let errorMessage = String(data: data, encoding: .utf8)
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                    return
                }
                
                // Try to decode successful response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ProfileResponse.self, from: data)
                    
                    print("✅ Profile check successful")
                    completion(.success(response))
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
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
        
        // Use direct URL request instead of the generic request method
        let url = URL(string: APIConfig.ekshaktiBaseURL + "/profile")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header if available
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No authentication token available for profile creation")
            completion(.failure(.unauthorized))
            return
        }
        
        print("🌐 Making direct POST request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profile creation network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    completion(.failure(.noData))
                    return
                }
                
                // If server returned an HTML page (login page), treat as unauthorized
                if let self = self, self.isHTMLResponse(httpResponse, data: data) {
                    Task { @MainActor in
                        TokenManager.shared.clearTokens()
                    }
                    completion(.failure(.unauthorized))
                    return
                }
                
                // Try to extract error message if status code is not successful
                if httpResponse.statusCode >= 400 {
                    // Handle invalid/expired tokens consistently
                    if self?.handleAuthErrorIfNeeded(data) == true {
                        completion(.failure(.unauthorized))
                        return
                    }
                    
                    // Handle other errors
                    let errorMessage = String(data: data, encoding: .utf8)
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                    return
                }
                
                // Try to decode successful response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ProfileResponse.self, from: data)
                    
                    print("✅ Profile created successfully")
                    completion(.success(response))
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
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
        
        // Use direct URL request instead of the generic request method
        let url = URL(string: APIConfig.ekshaktiBaseURL + "/profile")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication header if available
        if let authHeader = TokenManager.shared.getAuthorizationHeader() {
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No authentication token available for profile update")
            completion(.failure(.unauthorized))
            return
        }
        
        print("🌐 Making direct PUT request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Profile update network error: \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    completion(.failure(.noData))
                    return
                }
                
                // If server returned an HTML page (login page), treat as unauthorized
                if let self = self, self.isHTMLResponse(httpResponse, data: data) {
                    Task { @MainActor in
                        TokenManager.shared.clearTokens()
                    }
                    completion(.failure(.unauthorized))
                    return
                }
                
                // Try to extract error message if status code is not successful
                if httpResponse.statusCode >= 400 {
                    // Handle invalid/expired tokens consistently
                    if self?.handleAuthErrorIfNeeded(data) == true {
                        completion(.failure(.unauthorized))
                        return
                    }
                    
                    // Handle other errors
                    let errorMessage = String(data: data, encoding: .utf8)
                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                    return
                }
                
                // Try to decode successful response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ProfileResponse.self, from: data)
                    
                    print("✅ Profile updated successfully")
                    completion(.success(response))
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
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
