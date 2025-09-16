import Foundation
import Combine

// MARK: - Token Manager
@MainActor
class TokenManager: ObservableObject {
    static let shared = TokenManager()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"
    
    // MARK: - Initialization
    private init() {
        loadTokensFromStorage()
    }
    
    // MARK: - Token Management
    func storeTokens(accessToken: String, refreshToken: String) {
        print("🔐 TokenManager: Storing/updating authentication tokens")
        
        // Basic sanity checks to avoid storing invalid/dev fallback tokens
        let parts = accessToken.split(separator: ".")
        if parts.count != 3 || accessToken.contains("DEV_SIGNATURE_FOR_TESTING_ONLY") {
            print("⚠️ TokenManager: Rejected invalid or development fallback token. Not storing.")
            self.clearTokens()
            return
        }
        
        // Clear any existing tokens first
        if self.accessToken != nil {
            print("🔄 Updating existing tokens with new ones from signin")
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.isAuthenticated = true
        
        // Store in UserDefaults
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(refreshToken, forKey: refreshTokenKey)
        userDefaults.synchronize()
        
        print("✅ Tokens stored/updated successfully")
        print("   - Access Token: \(accessToken.prefix(20))...")
        print("   - Refresh Token: \(refreshToken.prefix(20))...")
    }
    
    func loadTokensFromStorage() {
        print("📥 TokenManager: Loading tokens from storage")
        
        self.accessToken = userDefaults.string(forKey: accessTokenKey)
        self.refreshToken = userDefaults.string(forKey: refreshTokenKey)
        self.isAuthenticated = accessToken != nil
        
        if isAuthenticated {
            print("✅ Tokens loaded from storage")
        } else {
            print("ℹ️ No tokens found in storage")
        }
    }
    
    func clearTokens() {
        print("🧹 TokenManager: Clearing authentication tokens")
        
        self.accessToken = nil
        self.refreshToken = nil
        self.isAuthenticated = false
        
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.synchronize()
        
        print("✅ Tokens cleared")
    }
    
    // MARK: - Token Access
    nonisolated func getAuthorizationHeader() -> String? {
        // Using UserDefaults directly to avoid actor isolation issues
        guard let token = UserDefaults.standard.string(forKey: accessTokenKey), !token.isEmpty else {
            print("⚠️ TokenManager: No access token available in UserDefaults")
            return nil
        }
        
        // Basic validation to ensure token looks like a JWT
        let parts = token.split(separator: ".")
        if parts.count != 3 {
            print("⚠️ TokenManager: Token does not appear to be a valid JWT format")
            return nil
        }
        
        print("✅ TokenManager: Authorization header created with token: \(token.prefix(15))...")
        return "Bearer \(token)"
    }
    
    nonisolated func hasValidToken() -> Bool {
        // Check if token exists in UserDefaults
        guard let token = UserDefaults.standard.string(forKey: accessTokenKey), !token.isEmpty else {
            print("⚠️ TokenManager: No access token found in UserDefaults")
            return false
        }
        
        print("🔑 TokenManager: Found access token in UserDefaults: \(token.prefix(15))...")
        
        // Basic JWT format validation
        let parts = token.split(separator: ".")
        if parts.count != 3 {
            print("⚠️ TokenManager: Token does not have valid JWT format (expected 3 parts, got \(parts.count))")
            return false
        }
        
        // Skip expiry validation for Google login tokens if they don't have standard JWT format
        // This is a workaround for cases where the token might be in a different format
        if token.contains("google") || token.contains("oauth") {
            print("🔑 TokenManager: Google/OAuth token detected, skipping expiry validation")
            return true
        }
        
        // For standard JWT tokens, validate expiry
        let payloadB64 = String(parts[1])
        // Base64URL decode
        var normalized = payloadB64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLen = 4 - (normalized.count % 4)
        if paddingLen < 4 { normalized += String(repeating: "=", count: paddingLen) }
        
        if let data = Data(base64Encoded: normalized),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // exp could be Int or Double
            var expTime: TimeInterval?
            if let exp = json["exp"] as? Double {
                expTime = exp
            } else if let exp = json["exp"] as? Int {
                expTime = TimeInterval(exp)
            }
            if let exp = expTime {
                let now = Date().timeIntervalSince1970
                if now >= exp {
                    print("⚠️ TokenManager: Access token expired")
                    return false
                } else {
                    print("✅ TokenManager: Token is valid and not expired")
                }
            } else {
                print("⚠️ TokenManager: Token does not contain expiry information")
            }
        } else {
            print("⚠️ TokenManager: Could not decode token payload")
        }
        
        return true
    }
    
    // MARK: - Token Refresh (Future Implementation)
    func refreshTokenIfNeeded() async throws {
        guard refreshToken != nil else {
            throw TokenError.noRefreshToken
        }
        
        // TODO: Implement token refresh logic when backend supports it
        print("🔄 TokenManager: Token refresh not yet implemented")
    }
    
    // MARK: - Debug
    func printTokenInfo() {
        print("🔍 TokenManager Status:")
        print("   - Is Authenticated: \(isAuthenticated)")
        print("   - Has Access Token: \(accessToken != nil)")
        print("   - Has Refresh Token: \(refreshToken != nil)")
        if let token = accessToken {
            print("   - Access Token Preview: \(String(token.prefix(20)))...")
        }
    }
}

// MARK: - Token Errors
enum TokenError: Error, LocalizedError {
    case noAccessToken
    case noRefreshToken
    case tokenExpired
    case refreshFailed
    
    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "No access token available"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "Access token has expired"
        case .refreshFailed:
            return "Failed to refresh token"
        }
    }
}
