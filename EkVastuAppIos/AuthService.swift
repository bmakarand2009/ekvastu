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
        
        networkService.request<GoogleLoginResponse>(
            endpoint: .googleLogin,
            method: .POST,
            body: requestData,
            headers: nil
        )
        .sink(
            receiveCompletion: { [weak self] completionResult in
                switch completionResult {
                case .finished:
                    print("✅ Google login request completed")
                case .failure(let error):
                    print("❌ Google login failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                }
            },
            receiveValue: { [weak self] (response: GoogleLoginResponse) in
                print("✅ Google login successful")
                print("   - Email: \(response.email)")
                print("   - Role: \(response.role)")
                
                DispatchQueue.main.async {
                    // Store tokens from backend response
                    TokenManager.shared.storeTokens(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken
                    )
                    
                    // Update tenant config if present
                    if let tenant = response.tenant {
                        TenantConfigManager.shared.updateSignInTenant(tenant)
                    }
                    
                    self?.isLoading = false
                    self?.errorMessage = nil
                    completion(.success(response))
                }
            }
        )
        .store(in: &cancellables)
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
        
        networkService.post<GoogleSignUpResponse>(
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
                    print("✅ Google signup request completed successfully")
                case .failure(let error):
                    let userFriendlyMessage = self?.extractUserFriendlyErrorMessage(from: error) ?? error.localizedDescription
                    print("❌ Google signup failed with error: \(userFriendlyMessage)")
                    self?.errorMessage = userFriendlyMessage
                    completion(.failure(error))
                }
            },
            receiveValue: { [weak self] (response: GoogleSignUpResponse) in
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
            }
        )
        .store(in: &cancellables)
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
}
