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
        guard let token = userDefaults.string(forKey: accessTokenKey) else {
            print("⚠️ TokenManager: No access token available")
            return nil
        }
        return "Bearer \(token)"
    }
    
    nonisolated func hasValidToken() -> Bool {
        let token = userDefaults.string(forKey: accessTokenKey)
        return token != nil && !token!.isEmpty
    }
    
    // MARK: - Token Refresh (Future Implementation)
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = refreshToken else {
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
