import Foundation
import Combine
import FirebaseAuth

// MARK: - Profile Manager
class ProfileManager: ObservableObject {    
    // Simple authentication check without retry
    private func checkAuthentication() -> Bool {
        return TokenManager.shared.hasValidToken()
    }
    static let shared = ProfileManager()
    
    @Published var currentProfile: ProfileData?
    @Published var isLoading = false
    @Published var profileExists = false
    @Published var errorMessage: String?
    
    private let profileService = ProfileService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Profile Management
    
    /// Check if profile exists and load it
    func checkAndLoadProfile() {
        // First check if user is authenticated
        guard checkAuthentication() else {
            print("⚠️ ProfileManager: Not authenticated, skipping profile check")
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.currentProfile = nil
                self?.profileExists = false
                self?.errorMessage = "Not authenticated"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        profileService.checkProfile { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let profileData = response.data {
                        // Profile exists
                        self?.currentProfile = profileData
                        self?.profileExists = true
                        print("✅ Profile loaded successfully: \(profileData.name)")
                    } else {
                        // Profile doesn't exist
                        self?.currentProfile = nil
                        self?.profileExists = false
                        self?.errorMessage = response.message ?? "No profile found for this contact. Please create profile first"
                        print("ℹ️ Profile not found: \(response.message ?? "Unknown")")
                    }
                    
                case .failure(let error):
                    // Handle error without retries
                    self?.currentProfile = nil
                    self?.profileExists = false
                    self?.errorMessage = error.localizedDescription
                    print("❌ Failed to check profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Create a new profile
    func createProfile(dob: String, placeOfBirth: String, timeOfBirth: String, completion: @escaping (Bool, String?) -> Void) {
        // First check if user is authenticated
        guard checkAuthentication() else {
            print("⚠️ ProfileManager: Not authenticated, skipping profile creation")
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
                completion(false, "Not authenticated")
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        profileService.createProfile(
            dob: dob,
            placeOfBirth: placeOfBirth,
            timeOfBirth: timeOfBirth
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let profileData = response.data {
                        // Profile created successfully
                        self?.currentProfile = profileData
                        self?.profileExists = true
                        self?.errorMessage = nil
                        print("✅ Profile created successfully: \(profileData.name)")
                        completion(true, response.message)
                    } else {
                        // Profile creation failed
                        self?.errorMessage = response.message ?? "Failed to create profile"
                        print("❌ Profile creation failed: \(response.message ?? "Unknown")")
                        completion(false, response.message)
                    }
                    
                case .failure(let error):
                    // Handle error without retries
                    self?.errorMessage = error.localizedDescription
                    print("❌ Failed to create profile: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    /// Update existing profile
    func updateProfile(placeOfBirth: String? = nil, timeOfBirth: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        // First check if user is authenticated
        guard checkAuthentication() else {
            print("⚠️ ProfileManager: Not authenticated, skipping profile update")
            DispatchQueue.main.async {
                self.errorMessage = "Not authenticated"
                completion(false, "Not authenticated")
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        profileService.updateProfile(
            placeOfBirth: placeOfBirth,
            timeOfBirth: timeOfBirth
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let profileData = response.data {
                        // Profile updated successfully
                        self?.currentProfile = profileData
                        self?.profileExists = true
                        self?.errorMessage = nil
                        print("✅ Profile updated successfully: \(profileData.name)")
                        completion(true, response.message)
                    } else {
                        // Profile update failed
                        self?.errorMessage = response.message ?? "Failed to update profile"
                        print("❌ Profile update failed: \(response.message ?? "Unknown")")
                        completion(false, response.message)
                    }
                    
                case .failure(let error):
                    // Handle error without retries
                    self?.errorMessage = error.localizedDescription
                    print("❌ Failed to update profile: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    /// Clear profile data (for logout)
    func clearProfile() {
        currentProfile = nil
        profileExists = false
        errorMessage = nil
        isLoading = false
    }
    
    /// Get profile data safely
    func getProfile() -> ProfileData? {
        return currentProfile
    }
    
    /// Check if profile exists
    func hasProfile() -> Bool {
        return profileExists && currentProfile != nil
    }
}