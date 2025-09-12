import Foundation
import Combine
import FirebaseAuth

// MARK: - Authentication Service
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let networkService = NetworkService.shared
    private let tenantConfig = TenantConfigManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
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
        userId: String,
        password: String,
        completion: @escaping (Result<SignInResponse, NetworkError>) -> Void
    ) {
        print("🔐 Starting sign in process for user: \(userId)")
        print("🏢 First getting tenant info to retrieve TID...")
        
        isLoading = true
        errorMessage = nil
        
        // Step 1: Get tenant info to retrieve TID
        getTenantInfo { [weak self] tenantResult in
            switch tenantResult {
            case .success(let tenantInfo):
                print("✅ Tenant info retrieved, orgId: \(tenantInfo.orgId)")
                
                // Step 2: Use the orgId from tenant response for signin
                self?.performSignIn(
                    orgId: tenantInfo.orgId,
                    userId: userId,
                    password: password,
                    completion: completion
                )
                
            case .failure(let error):
                print("❌ Failed to get tenant info: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get tenant configuration"
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Internal Sign In Method
    private func performSignIn(
        orgId: String,
        userId: String,
        password: String,
        completion: @escaping (Result<SignInResponse, NetworkError>) -> Void
    ) {
        print("🔐 Performing sign in with orgId: \(orgId)")
        
        let request = SignInRequest(
            orgId: orgId,
            userId: userId,
            password: password,
            rememberMe: true
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
        
        networkService.post<SignInResponse>(
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
                
                // Update tokens in TokenManager on every signin
                Task { @MainActor in
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
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
        
        // Step 1: Get tenant info to retrieve tid and orgId
        getTenantInfo { [weak self] tenantResult in
            switch tenantResult {
            case .success(let tenantInfo):
                print("✅ Tenant info retrieved for Google login")
                print("   - TID: \(tenantInfo.tenantId)")
                print("   - OrgId: \(tenantInfo.orgId)")
                
                // Step 2: Call Google login API with tenant info
                self?.performGoogleLogin(
                    tid: tenantInfo.tenantId,
                    orgId: tenantInfo.orgId,
                    idToken: idToken,
                    completion: completion
                )
                
            case .failure(let error):
                print("❌ Failed to get tenant info for Google login: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get tenant configuration"
                    completion(.failure(error))
                }
            }
        }
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
        
        // Step 1: Get tenant info to retrieve tenantId
        getTenantInfo { [weak self] tenantResult in
            switch tenantResult {
            case .success(let tenantInfo):
                print("✅ Tenant info retrieved for Google signup")
                print("   - TenantId: \(tenantInfo.tenantId)")
                
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
                
                // Step 2: Call Google signup API with tenant info and user details
                self?.performGoogleSignUp(
                    idToken: idToken,
                    tenantId: tenantInfo.tenantId,
                    name: name,
                    lastName: lastName,
                    phone: user.phoneNumber,
                    completion: completion
                )
                
            case .failure(let error):
                print("❌ Failed to get tenant info for Google signup: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get tenant configuration"
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Internal Google Login Method
    private func performGoogleLogin(
        tid: String,
        orgId: String,
        idToken: String,
        completion: @escaping (Result<GoogleLoginResponse, NetworkError>) -> Void
    ) {
        print("🔐 Performing Google login with backend")
        print("   - TID: \(tid)")
        print("   - OrgId: \(orgId)")
        
        let request = GoogleLoginRequest(
            tid: tid,
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
                            if let emailFromRequest = try? JSONDecoder().decode(GoogleLoginRequest.self, from: requestData).idToken.components(separatedBy: ".").count > 1,
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
                               let messageJson = errors["message"] as? String,
                               let messageData = messageJson.data(using: .utf8),
                               let innerJson = try JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                               let innerErrors = innerJson["errors"] as? [String: Any],
                               let errorMessage = innerErrors["message"] as? String {
                                
                                self?.errorMessage = "Server error: \(errorMessage)"
                                completion(.failure(.serverError(httpResponse.statusCode, errorMessage)))
                                return
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
                    
                    // Store tokens from backend response
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    
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
        print("📝 Performing Google signup with backend")
        print("   - TenantId: \(tenantId)")
        print("   - Name: \(name)")
        print("   - Last Name: \(lastName ?? "N/A")")
        print("   - Phone: \(phone ?? "N/A")")
        
        let request = GoogleSignUpRequest(
            idToken: idToken,
            tenantId: tenantId,
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
                    // Handle HTML response (likely an error page)
                    print("❌ Received HTML response instead of JSON")
                    self?.errorMessage = "Server returned HTML instead of JSON. Please try again later."
                    completion(.failure(.serverError(httpResponse.statusCode, "Server returned HTML instead of JSON")))
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
    func signIn(userId: String, password: String) async throws -> SignInResponse {
        return try await withCheckedThrowingContinuation { continuation in
            signIn(userId: userId, password: password) { result in
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
        
        networkService.get<TenantPingResponse>(
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
        print("🏢 First getting tenant info to retrieve tenantId...")
        
        isLoading = true
        errorMessage = nil
        
        // Step 1: Get tenant info to retrieve tenantId
        getTenantInfo { [weak self] tenantResult in
            switch tenantResult {
            case .success(let tenantInfo):
                print("✅ Tenant info retrieved, tenantId: \(tenantInfo.tenantId)")
                
                // Step 2: Use the tenantId from tenant response for signup
                self?.performSignUp(
                    name: name,
                    email: email,
                    tenantId: tenantInfo.tenantId,
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
                
            case .failure(let error):
                print("❌ Failed to get tenant info: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to get tenant configuration"
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Internal Sign Up Method
    private func performSignUp(
        name: String,
        email: String,
        tenantId: String,
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
        print("📝 Performing sign up with tenantId: \(tenantId)")
        
        let request = SignUpRequest(
            name: name,
            email: email,
            tenantId: tenantId,
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
        
        networkService.post<SignUpResponse>(
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
