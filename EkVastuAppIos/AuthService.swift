import Foundation
import Combine
import FirebaseAuth

// MARK: - Authentication Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let networkService = NetworkService.shared
    private let tenantConfig = TenantConfigManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // Use NetworkService's printCurlCommand function
    
    // MARK: - Helper Methods
    private func extractUserFriendlyErrorMessage(from error: NetworkError) -> String {
        switch error {
        case .serverError(let statusCode, let errorMessage):
            // Try to parse the nested error structure
            if let errorData = errorMessage?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errors = json["errors"] as? [String: Any],
               let messageString = errors["message"] as? String {
                
                // The message itself might be a JSON string, try to parse it
                if let messageData = messageString.data(using: .utf8),
                   let messageJson = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                   let actualMessage = messageJson["message"] as? String {
                    return actualMessage
                }
                
                // If not nested JSON, return the message string as is
                return messageString
            }
            
            // Fallback to original error message
            return errorMessage ?? "Server error (\(statusCode))"
            
        default:
            return error.localizedDescription
        }
    }
    
    // MARK: - Sign In Method (with automatic tenant ping)
    func signIn(
        email: String,
        password: String,
        completion: @escaping (Result<SignInResponse, NetworkError>) -> Void
    ) {
        print("🔐 Starting sign in for user: \(email)")
        
        isLoading = true
        errorMessage = nil
        
        // Always use tidDebug or tidRelease from APIConfig
        let tid = networkService.getCurrentTenantId()
        print("✅ Using tenant ID from APIConfig: \(tid)")
        
        // Use the tid directly for signin
        self.performSignIn(
            tid: tid,
            email: email,
            password: password,
            completion: completion
        )
    }
    
    // MARK: - Internal Sign In Method
    private func performSignIn(
        tid: String,
        email: String,
        password: String,
        completion: @escaping (Result<SignInResponse, NetworkError>) -> Void
    ) {
        // Override the passed tid with the dynamic tenant ID based on the base URL
        let dynamicTid = networkService.getCurrentTenantId()
        print("🔐 Performing sign in with tid: \(dynamicTid)")
        
        let request = SignInRequest(
            tid: dynamicTid,
            email: email,
            password: password,
            authType: "email"
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode sign in request")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
                completion(.failure(.decodingError(NSError(domain: "EncodingError", code: 0))))
            }
            return
        }
        
        networkService.post(
            endpoint: .signin,
            body: requestData,
            headers: nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                switch completionResult {
                case .finished:
                    print("✅ Sign in request completed successfully")
                case .failure(let error):
                    print("❌ Sign in failed with error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            },
            receiveValue: { [weak self] (response: SignInResponse) in
                print("📥 Sign in response received")
                print("User: \(response.contact.fullName)")
                print("Email: \(response.email)")
                print("Role: \(response.role)")
                print("Access Token: \(response.accessToken.prefix(20))...")
                
                // Update tokens in TokenManager on every signin and then fetch profile
                Task { @MainActor in
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    // Trigger profile auto-create/fetch with the new access token
                    ProfileService.shared.checkProfile { _ in }
                }
                
                // Update tenant configuration from signin response if available
                if let tenant = response.tenant {
                    Task { @MainActor in
                        self?.tenantConfig.updateSignInTenant(tenant)
                    }
                }
                
                self?.errorMessage = nil
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Google Login Method
    func googleLogin(
        idToken: String,
        completion: @escaping (Result<GoogleLoginResponse, NetworkError>) -> Void
    ) {
        print("🔐 Starting Google login with backend...")
        
        isLoading = true
        errorMessage = nil
        
        // Always use tidDebug or tidRelease from APIConfig
        let tid = networkService.getCurrentTenantId()
        // Use "PostFix" as a default orgId since we're not using the tenant info API
        let orgId = "PostFix"
        
        print("✅ Using tenant ID from APIConfig: \(tid)")
        print("   - TID: \(tid)")
        print("   - OrgId: \(orgId)")
        
        // Call Google login API directly with APIConfig tid
        self.performGoogleLogin(
            tid: tid,
            orgId: orgId,
            idToken: idToken,
            completion: completion
        )
    }
    
    // MARK: - Google Signup Method
    func googleSignUp(
        idToken: String,
        user: FirebaseAuth.User,
        completion: @escaping (Result<GoogleSignUpResponse, NetworkError>) -> Void
    ) {
        print("🔐 Starting Google signup with backend...")
        
        isLoading = true
        errorMessage = nil
        
        // Always use tidDebug or tidRelease from APIConfig
        let tid = networkService.getCurrentTenantId()
        print("✅ Using tenant ID from APIConfig: \(tid)")
        
        // Extract user details from Firebase User
        let name = user.displayName?.components(separatedBy: " ").first ?? ""
        var lastName: String? = nil
        
        // Try to extract last name if available
        if let displayName = user.displayName, displayName.contains(" ") {
            let components = displayName.components(separatedBy: " ")
            if components.count > 1 {
                lastName = components.dropFirst().joined(separator: " ")
            }
        }
        
        // Call Google signup API directly with APIConfig tid
        self.performGoogleSignUp(
            idToken: idToken,
            tenantId: tid,
            name: name,
            lastName: lastName,
            phone: user.phoneNumber,
            completion: completion
        )
    }
    
    // MARK: - Internal Google Login Method
    private func performGoogleLogin(
        tid: String,
        orgId: String,
        idToken: String,
        completion: @escaping (Result<GoogleLoginResponse, NetworkError>) -> Void
    ) {
        // Override the passed tid with the dynamic tenant ID based on the base URL
        let dynamicTid = networkService.getCurrentTenantId()
        print("🔐 Performing Google login with backend")
        print("   - TID: \(dynamicTid)")
        print("   - OrgId: \(orgId)")
        
        let request = GoogleLoginRequest(
            tid: dynamicTid,
            orgId: orgId,
            idToken: idToken
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode Google login request")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
                completion(.failure(.decodingError(NSError(domain: "EncodingError", code: 0))))
            }
            return
        }
        
        // Use direct URL request instead of the generic request method
        let url = URL(string: APIConfig.baseURL + "/smobile/rest/glogin")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 Making direct POST request to: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        networkService.printCurlCommand(for: urlRequest)
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        networkService.printCurlCommand(for: urlRequest)
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Google login network error: \(error.localizedDescription)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    self?.errorMessage = "Invalid server response"
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    self?.errorMessage = "No data received from server"
                    completion(.failure(.noData))
                    return
                }
                
                // Try to extract error message if status code is not successful
                if httpResponse.statusCode >= 400 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Response data: \(responseString)")
                        
                        // Try to extract a more user-friendly error message
                        if responseString.contains("Google services file not found") {
                            print("⚠️ Server configuration issue detected - using development fallback")
                            self?.errorMessage = nil
                            
                            #if DEBUG
                            // In development mode, create a mock successful response using the Firebase user's email
                            if let _ = try? JSONDecoder().decode(GoogleLoginRequest.self, from: requestData).idToken.components(separatedBy: ".").count > 1,
                               let payload = try? JSONDecoder().decode(GoogleLoginRequest.self, from: requestData).idToken.components(separatedBy: ".")[1],
                               let data = Data(base64Encoded: payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let email = json["email"] as? String {
                                self?.useDevelopmentFallbackAuth(email: email, completion: completion)
                            } else {
                                // Fallback to generic email if we can't extract it
                                self?.useDevelopmentFallbackAuth(email: "user@example.com", completion: completion)
                            }
                            #else
                            // In production, show the error
                            self?.errorMessage = "Google login is not properly configured on the server. Please contact support."
                            completion(.failure(.serverError(httpResponse.statusCode, "Google login is not properly configured on the server")))
                            #endif
                            return
                        }
                        
                        // Try to parse the error JSON
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let errors = json["errors"] as? [String: Any],
                               let messageJson = errors["message"] as? String {
                                
                                // Try to parse the inner JSON message
                                if let messageData = messageJson.data(using: .utf8),
                                   let innerJson = try JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                                   let errorMessage = innerJson["message"] as? String {
                                    
                                    self?.errorMessage = errorMessage
                                    completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                                    return
                                } else {
                                    // If inner JSON parsing fails, use the messageJson directly
                                    self?.errorMessage = messageJson
                                    completion(.failure(.serverError(httpResponse.statusCode, messageJson)))
                                    return
                                }
                            }
                        } catch {
                            // If JSON parsing fails, use the raw response
                            self?.errorMessage = "Server error: \(responseString)"
                            completion(.failure(.serverError(httpResponse.statusCode, responseString)))
                            return
                        }
                    }
                    
                    // Fallback error message
                    self?.errorMessage = "Server error (\(httpResponse.statusCode))"
                    completion(.failure(.serverError(httpResponse.statusCode, nil)))
                    return
                }
                
                // Try to decode successful response
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(GoogleLoginResponse.self, from: data)
                    
                    print("✅ Google login successful")
                    print("   - Email: \(response.email)")
                    print("   - Role: \(response.role)")
                    
                    // Store tokens from backend response and then fetch profile
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    // Trigger profile auto-create/fetch with the new access token
                    ProfileService.shared.checkProfile { _ in }
                    
                    // Update tenant config if present
                    if let tenant = response.tenant {
                        TenantConfigManager.shared.updateSignInTenant(tenant)
                    }
                    
                    self?.errorMessage = nil
                    completion(.success(response))
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    
                    // Try to decode as string for better error message
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                        self?.errorMessage = "Server returned invalid format. Please try again later."
                    } else {
                        self?.errorMessage = "Failed to decode response"
                    }
                    
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // MARK: - Internal Google Signup Method
    private func performGoogleSignUp(
        idToken: String,
        tenantId: String,
        name: String,
        lastName: String?,
        phone: String?,
        completion: @escaping (Result<GoogleSignUpResponse, NetworkError>) -> Void
    ) {
        // Override the passed tenantId with the dynamic tenant ID based on the base URL
        let dynamicTid = networkService.getCurrentTenantId()
        print("📝 Performing Google signup with backend")
        print("   - TenantId: \(dynamicTid)")
        print("   - Name: \(name)")
        print("   - Last Name: \(lastName ?? "N/A")")
        print("   - Phone: \(phone ?? "N/A")")
        
        let request = GoogleSignUpRequest(
            idToken: idToken,
            tenantId: dynamicTid,
            orgId: "PostFix", // Adding required orgId parameter
            name: name,
            lastName: lastName,
            phone: phone
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode Google signup request")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
                completion(.failure(.decodingError(NSError(domain: "EncodingError", code: 0))))
            }
            return
        }
        
        // Use direct URL request instead of the post method to handle raw response
        let url = URL(string: APIConfig.baseURL + "/smobile/rest/signup")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 Making direct POST request to: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        networkService.printCurlCommand(for: urlRequest)
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Google signup network error: \(error.localizedDescription)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    self?.errorMessage = "Invalid server response"
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    self?.errorMessage = "No data received from server"
                    completion(.failure(.noData))
                    return
                }
                
                // Check if response is JSON or HTML
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                   contentType.contains("text/html") {
                    // Handle HTML response (likely a login redirect)
                    print("❌ Received HTML login page instead of JSON - API requires authentication")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw HTML response: \(responseString.prefix(500))...")
                    }
                    self?.errorMessage = "Authentication required. The signup endpoint is redirecting to login. Please contact support."
                    completion(.failure(.serverError(httpResponse.statusCode, "API endpoint requires authentication for signup")))
                    return
                }
                
                // Also check if the response data looks like HTML even without proper content-type
                if let responseString = String(data: data, encoding: .utf8),
                   responseString.lowercased().contains("<!doctype html") || responseString.lowercased().contains("<html") {
                    print("❌ Detected HTML response without proper content-type header")
                    print("Raw HTML response: \(responseString.prefix(500))...")
                    self?.errorMessage = "Server configuration error. The signup endpoint is returning a login page instead of processing the request."
                    completion(.failure(.serverError(httpResponse.statusCode, "Server returned HTML login page instead of JSON")))
                    return
                }
                
                // Try to decode as JSON
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(GoogleSignUpResponse.self, from: data)
                    
                    print("📥 Google signup response received")
                    print("Success: \(response.success)")
                    if let message = response.message {
                        print("Message: \(message)")
                    }
                    if let userData = response.data {
                        print("User ID: \(userData.id ?? "N/A")")
                        print("Email: \(userData.email ?? "N/A")")
                        print("Name: \(userData.name ?? "N/A")")
                    }
                    
                    self?.errorMessage = nil
                    completion(.success(response))
                } catch {
                    print("❌ Failed to decode response: \(error)")
                    
                    // Try to decode as string for better error message
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                        self?.errorMessage = "Server returned invalid format. Please try again later."
                    } else {
                        self?.errorMessage = "Failed to decode response"
                    }
                    
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // MARK: - Sign In with Async/Await
    @MainActor
    func signIn(email: String, password: String) async throws -> SignInResponse {
        return try await withCheckedThrowingContinuation { continuation in
            signIn(email: email, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Tenant Ping Method
    func getTenantInfo(
        completion: @escaping (Result<TenantPingResponse, NetworkError>) -> Void
    ) {
        print("🏢 Getting tenant info for: \(APIConfig.tenantName)")
        
        isLoading = true
        errorMessage = nil
        
        networkService.get(
            endpoint: .tenantPing,
            headers: nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                switch completionResult {
                case .finished:
                    print("✅ Tenant info request completed successfully")
                case .failure(let error):
                    print("❌ Tenant info failed with error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            },
            receiveValue: { [weak self] (response: TenantPingResponse) in
                print("📥 Tenant info response received")
                print("Tenant Name: \(response.name)")
                print("Organization ID: \(response.orgId)")
                print("Tenant ID: \(response.tenantId)")
                
                DispatchQueue.main.async {
                    // Update global tenant configuration
                    Task { @MainActor in
                        self?.tenantConfig.updateTenantConfig(response)
                    }
                    
                    self?.isLoading = false
                    self?.errorMessage = nil
                    completion(.success(response))
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Tenant Info with Async/Await
    @MainActor
    func getTenantInfo() async throws -> TenantPingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            getTenantInfo { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Sign Up Method (with automatic tenant ping)
    func signUp(
        name: String,
        email: String,
        lastName: String? = nil,
        phone: String? = nil,
        referral: String? = nil,
        interestedIn: String? = nil,
        leadSource: String? = nil,
        description: String? = nil,
        line1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        timezone: String? = nil,
        completion: @escaping (Result<SignUpResponse, NetworkError>) -> Void
    ) {
        print("📝 Starting sign up process for user: \(email)")
        
        isLoading = true
        errorMessage = nil
        
        // Always use tidDebug or tidRelease from APIConfig
        let tid = networkService.getCurrentTenantId()
        print("✅ Using tenant ID from APIConfig: \(tid)")
        
        // Use the tid directly for signup
        self.performSignUp(
            name: name,
            email: email,
            tenantId: tid,
            lastName: lastName,
            phone: phone,
            referral: referral,
            interestedIn: interestedIn,
            leadSource: leadSource,
            description: description,
            line1: line1,
            city: city,
            state: state,
            zip: zip,
            country: country,
            timezone: timezone,
            completion: completion
        )
    }
    
    // MARK: - Internal Sign Up Method
    private func performSignUp(
        name: String,
        email: String,
        tenantId: String, // Parameter name remains the same for compatibility
        lastName: String?,
        phone: String?,
        referral: String?,
        interestedIn: String?,
        leadSource: String?,
        description: String?,
        line1: String?,
        city: String?,
        state: String?,
        zip: String?,
        country: String?,
        timezone: String?,
        completion: @escaping (Result<SignUpResponse, NetworkError>) -> Void
    ) {
        // Override the passed tenantId with the dynamic tenant ID based on the base URL
        let dynamicTid = networkService.getCurrentTenantId()
        print("📝 Performing sign up with tenantId: \(dynamicTid)")
        
        let request = SignUpRequest(
            name: name,
            email: email,
            tid: dynamicTid, // Using dynamic tenant ID
            orgId: "PostFix", // Adding required orgId parameter
            lastName: lastName,
            phone: phone,
            referral: referral,
            interestedIn: interestedIn,
            leadSource: leadSource,
            description: description,
            line1: line1,
            city: city,
            state: state,
            zip: zip,
            country: country,
            timezone: timezone
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode sign up request")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
                completion(.failure(.decodingError(NSError(domain: "EncodingError", code: 0))))
            }
            return
        }
        
        networkService.post(
            endpoint: .signup,
            body: requestData,
            headers: nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completionResult in
                self?.isLoading = false
                
                switch completionResult {
                case .finished:
                    print("✅ Sign up request completed successfully")
                case .failure(let error):
                    let userFriendlyMessage = self?.extractUserFriendlyErrorMessage(from: error) ?? error.localizedDescription
                    print("❌ Sign up failed with error: \(userFriendlyMessage)")
                    self?.errorMessage = userFriendlyMessage
                    completion(.failure(error))
                }
            },
            receiveValue: { [weak self] (response: SignUpResponse) in
                print("📥 Sign up response received")
                print("Email: \(response.email)")
                print("Role: \(response.role)")
                print("Name: \(response.contact.fullName)")
                print("Access Token: \(response.accessToken.prefix(20))...")
                
                // Store tokens from signup response and then fetch profile
                Task { @MainActor in
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken ?? ""
                    )
                    // Trigger profile auto-create/fetch with the new access token
                    ProfileService.shared.checkProfile { _ in }
                }
                
                // Update tenant configuration if available
                if let tenant = response.tenant {
                    Task { @MainActor in
                        self?.tenantConfig.updateSignInTenant(tenant)
                    }
                }
                
                self?.errorMessage = nil
                completion(.success(response))
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Sign Up with Async/Await
    @MainActor
    func signUp(
        name: String,
        email: String,
        lastName: String? = nil,
        phone: String? = nil,
        referral: String? = nil,
        interestedIn: String? = nil,
        leadSource: String? = nil,
        description: String? = nil,
        line1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        timezone: String? = nil
    ) async throws -> SignUpResponse {
        return try await withCheckedThrowingContinuation { continuation in
            signUp(
                name: name,
                email: email,
                lastName: lastName,
                phone: phone,
                referral: referral,
                interestedIn: interestedIn,
                leadSource: leadSource,
                description: description,
                line1: line1,
                city: city,
                state: state,
                zip: zip,
                country: country,
                timezone: timezone
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Email Login Method
    func emailLogin(
        email: String,
        password: String,
        completion: @escaping (Result<SignInResponse, NetworkError>) -> Void
    ) {
        print("🔐 Starting email login for user: \(email)")
        
        isLoading = true
        errorMessage = nil
        
        // Use dynamic tenant ID based on the base URL
        let tid = networkService.getCurrentTenantId()
        
        let request = EmailLoginRequest(
            tid: tid,
            email: email,
            password: password
        )
        
        guard let requestData = try? JSONEncoder().encode(request) else {
            print("❌ Failed to encode email login request")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to prepare request"
                completion(.failure(.decodingError(NSError(domain: "EncodingError", code: 0))))
            }
            return
        }
        
        // Use direct URL request for the new API endpoint
        let url = URL(string: "https://api.wajooba.xyz/smobile/tenant/email/login")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🌐 Making direct POST request to: \(url.absoluteString)")
        if let bodyString = String(data: requestData, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }
        
        // Print curl command for debugging
        networkService.printCurlCommand(for: urlRequest)
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Email login network error: \(error.localizedDescription)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    self?.errorMessage = "Invalid server response"
                    completion(.failure(.invalidRequest))
                    return
                }
                
                print("📥 Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    print("❌ No data received")
                    self?.errorMessage = "No data received from server"
                    completion(.failure(.noData))
                    return
                }
                
                // First, try to decode as EmailLoginResponse to handle both success and error cases
                do {
                    let decoder = JSONDecoder()
                    let emailResponse = try decoder.decode(EmailLoginResponse.self, from: data)
                    
                    // Check if the response contains an error message
                    if let errorMsg = emailResponse.data.msg {
                        print("❌ Email login failed with message: \(errorMsg)")
                        self?.errorMessage = errorMsg
                        completion(.failure(.serverError(httpResponse.statusCode, errorMsg)))
                        return
                    }
                    
                    // Check if we have the required authentication data
                    guard let accessToken = emailResponse.data.accessToken,
                          let refreshToken = emailResponse.data.refreshToken,
                          let email = emailResponse.data.email,
                          let role = emailResponse.data.role,
                          let contact = emailResponse.data.contact else {
                        print("❌ Email login response missing required fields")
                        self?.errorMessage = "Server response missing required authentication data"
                        completion(.failure(.decodingError(NSError(domain: "MissingData", code: 0))))
                        return
                    }
                    
                    print("✅ Email login successful")
                    print("   - Email: \(email)")
                    print("   - Role: \(role)")
                    
                    // Create a SignInResponse from the EmailLoginResponse data
                    let signInResponse = SignInResponse(
                        accessToken: accessToken,
                        refreshToken: refreshToken,
                        email: email,
                        isNewProfile: false, // Default value
                        role: role,
                        contact: contact,
                        tenant: nil, // No tenant info in this response
                        orgList: nil // No org list in this response
                    )
                    
                    // Store tokens
                    TokenManager.shared.storeTokens(
                        accessToken: accessToken,
                        refreshToken: refreshToken
                    )
                    
                    self?.errorMessage = nil
                    completion(.success(signInResponse))
                    
                } catch {
                    // If we couldn't decode as EmailLoginResponse, try to extract error message
                    print("❌ Failed to decode email login response: \(error)")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(responseString)")
                        
                        // Try to extract error message from JSON
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let dataObj = json["data"] as? [String: Any],
                               let errorMsg = dataObj["msg"] as? String {
                                self?.errorMessage = errorMsg
                                completion(.failure(.serverError(httpResponse.statusCode, errorMsg)))
                                return
                            }
                        } catch {
                            // JSON parsing failed, use the raw response
                            self?.errorMessage = "Invalid credentials or server error"
                        }
                    }
                    
                    self?.errorMessage = "Login failed. Please check your credentials."
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Development Fallback Authentication
    @MainActor
    private func useDevelopmentFallbackAuth(email: String, completion: @escaping (Result<GoogleLoginResponse, NetworkError>) -> Void) {
        print("🔧 Using development fallback authentication for: \(email)")
        
        // Create mock user data
        let mockContact = Contact(
            id: "dev-user-id",
            guId: "dev-guid",
            email: email,
            fullName: "Development User",
            name: "Development",
            lastName: "User",
            phone: nil,
            picture: nil,
            imageUrl: nil,
            isEmailVerified: true,
            isFirstLogin: false,
            isAdminVerified: true,
            hasAcceptedTerms: true,
            isLocalPicture: false,
            balance: nil,
            description: nil,
            grnNumber: nil
        )
        
        // Create a properly formatted JWT token that will pass validation
        // Format: header.payload.signature (all base64 encoded)
        let header = ["alg": "HS256", "typ": "JWT"]
        let headerJson = try! JSONSerialization.data(withJSONObject: header)
        let headerBase64 = headerJson.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        let now = Int(Date().timeIntervalSince1970)
        let payload = [
            "sub": "dev-user-id",
            "name": "Development User",
            "email": email,
            "iat": now,
            "exp": now + 3600,
            "iss": "development-fallback"
        ] as [String : Any]
        let payloadJson = try! JSONSerialization.data(withJSONObject: payload)
        let payloadBase64 = payloadJson.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Simple signature (in production this would be cryptographically signed)
        let signatureBase64 = "DEV_SIGNATURE_FOR_TESTING_ONLY"
            .data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Combine to form JWT token
        let jwtToken = "\(headerBase64).\(payloadBase64).\(signatureBase64)"
        
        // Create mock response with the JWT token
        let mockResponse = GoogleLoginResponse(
            accessToken: jwtToken,
            refreshToken: "dev-refresh-token-\(UUID().uuidString)",
            email: email,
            isNewProfile: false,
            role: "user",
            contact: mockContact,
            tenant: nil,
            orgList: nil
        )
        
        // Store tokens
        TokenManager.shared.storeTokens(
            accessToken: mockResponse.accessToken,
            refreshToken: mockResponse.refreshToken
        )
        
        print("✅ Development fallback authentication successful")
        print("   - Access Token: \(mockResponse.accessToken.prefix(20))...")
        print("   - Using properly formatted JWT token for development")
        
        // Return success
        completion(.success(mockResponse))
    }
}
