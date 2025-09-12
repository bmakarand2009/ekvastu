import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    
    #if targetEnvironment(simulator)
    // For simulator testing
    var mockUser: MockUser?
    #endif
    
    static let shared = AuthenticationManager()
    
    init() {
        // Check Firebase auth state and clear local data if account doesn't exist
        checkFirebaseAuthState()
    }
    
    // Check Firebase auth state and verify account exists
    private func checkFirebaseAuthState() {
        print("=== CHECKING FIREBASE AUTH STATE ===")
        
        // Check if there's a cached Firebase user
        if let user = Auth.auth().currentUser {
            print("Found cached Firebase user: \(user.uid)")
            
            // Force reload user to check if account still exists on Firebase
            user.reload { [weak self] error in
                if let error = error as NSError? {
                    // Check if error indicates user doesn't exist
                    if error.code == AuthErrorCode.userNotFound.rawValue || 
                       error.code == AuthErrorCode.userDisabled.rawValue ||
                       error.code == AuthErrorCode.userTokenExpired.rawValue {
                        print("✗ Firebase account doesn't exist or is disabled - clearing all data")
                        self?.clearAllUserData()
                    } else {
                        print("Error reloading user: \(error.localizedDescription)")
                        // Try to get a fresh token to verify
                        self?.verifyWithFreshToken(user: user)
                    }
                } else {
                    // User exists and is valid
                    print("✓ Firebase account exists and is valid")
                    DispatchQueue.main.async {
                        self?.handleValidFirebaseAccount(user: user)
                    }
                }
            }
        } else {
            print("No cached Firebase user - checking for orphaned keystore data")
            // No Firebase user - clear all local data
            print("No Firebase user found - clearing all local data")
            clearAllUserData()
        }
    }
    
    // Handle case where Firebase account exists
    private func handleValidFirebaseAccount(user: User) {
        print("Firebase account valid - proceeding with authentication")
        self.user = user
        self.isAuthenticated = true
    }
    
    // Verify with fresh token
    private func verifyWithFreshToken(user: User) {
        user.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.userNotFound.rawValue || 
                   error.code == AuthErrorCode.userDisabled.rawValue {
                    print("✗ Firebase account doesn't exist - clearing all data")
                    self?.clearAllUserData()
                } else {
                    print("Token refresh error: \(error.localizedDescription)")
                    // Sign out and clear data to be safe
                    self?.clearAllUserData()
                }
            } else if token != nil {
                print("✓ Got fresh token - account is valid")
                DispatchQueue.main.async {
                    self?.handleValidFirebaseAccount(user: user)
                }
            } else {
                print("✗ No token received - clearing data")
                self?.clearAllUserData()
            }
        }
    }
    
    // Clear all user data from Firebase, Keychain, UserDefaults, and Tokens
    func clearAllUserData() {
        print("=== CLEARING ALL USER DATA ===")
        
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
            print("✓ Signed out from Firebase")
        } catch {
            print("✗ Error signing out from Firebase: \(error.localizedDescription)")
        }
        
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        print("✓ Signed out from Google")
        
        // Clear UserDefaults
        let userDefaultsKeys = [
            "user_id", "user_email", "user_name", "user_phone", 
            "user_role", "user_picture", "hasCompletedUserDetails",
            "hasCompletedPropertyAddress", "userDetails", "propertyAddresses"
        ]
        for key in userDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
        print("✓ Cleared UserDefaults")
        
        // Clear tokens and authentication state on main thread
        DispatchQueue.main.async { [weak self] in
            TokenManager.shared.clearTokens()
            print("✓ Cleared tokens")
            
            // Clear profile data
            ProfileManager.shared.clearProfile()
            print("✓ Cleared profile data")
            
            self?.user = nil
            self?.isAuthenticated = false
            self?.authError = nil
            print("✓ Reset authentication state")
        }
    }
    
    // Public sign out method
    func signOut() {
        clearAllUserData()
    }
    
    // Check for orphaned keystore data when no Firebase user exists
    private func checkForOrphanedKeystoreData() {
        print("Checking for orphaned keystore data...")
        
        if KeychainManager.hasAnyUserDetails() {
            print("⚠️ Found orphaned keystore data with no Firebase user - cleaning up")
            KeychainManager.deleteAllUserDetails()
            print("✓ Orphaned keystore data cleaned")
        }
        
        // Show onboarding since no valid authentication exists
        showOnboardingScreen()
    }
    
    // Clear authentication state and show onboarding
    private func clearAuthenticationAndShowOnboarding() {
        // Sign out from Firebase and Google
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Error during sign out: \(error.localizedDescription)")
        }
        
        // Reset authentication state
        self.user = nil
        self.isAuthenticated = false
        
        // Reset static flags
        AuthenticationManager.hasCompletedUserDetails = false
        AuthenticationManager.hasCompletedPropertyAddress = false
        AuthenticationManager.isCheckingUserStatus = false
        
        // Clear all local data
        clearAllLocalData()
        
        print("✓ Authentication cleared - showing onboarding")
    }
    
    // Show onboarding screen
    private func showOnboardingScreen() {
        print("✓ Showing onboarding screen")
        // Authentication state is already false, so onboarding will show
    }
    
    // Check if this is the first launch after app installation
    private func isFirstLaunchAfterInstallation() -> Bool {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.synchronize()
            return true
        }
        return false
    }
    
    // Perform complete authentication reset - clears everything
    private func performCompleteAuthenticationReset() {
        print("=== PERFORMING COMPLETE AUTHENTICATION RESET ===")
        
        // 1. Sign out from Firebase
        do {
            try Auth.auth().signOut()
            print("✓ Firebase sign out completed")
        } catch {
            print("⚠️ Firebase sign out error: \(error.localizedDescription)")
        }
        
        // 2. Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        print("✓ Google sign out completed")
        
        // 3. Clear all UserDefaults
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key != "HasLaunchedBefore" { // Keep the launch flag
                defaults.removeObject(forKey: key)
            }
        }
        defaults.synchronize()
        print("✓ UserDefaults cleared")
        
        // 4. Clear all Keychain data
        KeychainHelper.clearKeychain()
        KeychainManager.deleteAllUserDetails()
        print("✓ Keychain cleared")
        
        // 5. Clear Firebase Auth cache
        clearFirebaseAuthCache()
        print("✓ Firebase Auth cache cleared")
        
        // 6. Reset all authentication state
        self.user = nil
        self.isAuthenticated = false
        AuthenticationManager.hasCompletedUserDetails = false
        AuthenticationManager.hasCompletedPropertyAddress = false
        AuthenticationManager.isCheckingUserStatus = false
        
        print("=== COMPLETE AUTHENTICATION RESET FINISHED ===")
        print("App is now in fresh installation state")
    }
    
    // Clear Firebase Auth cache completely
    private func clearFirebaseAuthCache() {
        // Clear Firebase Auth internal cache
        if let user = Auth.auth().currentUser {
            do {
                try Auth.auth().signOut()
            } catch {
                print("Error clearing Firebase cache: \(error.localizedDescription)")
            }
        }
        
        // Clear any Firebase-related UserDefaults
        let firebaseKeys = ["firebase_session_cache", "firebase_user_cache", "FIRAuthAPNSToken"]
        for key in firebaseKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
    
    // Verify if the user account actually exists on Firebase servers
    private func verifyAccountExistsOnFirebase(user: User, completion: @escaping (Bool) -> Void) {
        // Try to get a fresh token with force refresh to verify account exists
        user.getIDToken { token, error in
            if let error = error {
                let nsError = error as NSError
                print("Token refresh failed with error: \(error.localizedDescription)")
                print("Error code: \(nsError.code)")
                
                // Check for specific Firebase Auth error codes that indicate deleted user
                if nsError.domain == "FIRAuthErrorDomain" {
                    switch nsError.code {
                    case 17011: // FIRAuthErrorCodeUserNotFound
                        print("User not found on Firebase - account was deleted")
                        completion(false)
                        return
                    case 17014: // FIRAuthErrorCodeUserDisabled
                        print("User account disabled on Firebase")
                        completion(false)
                        return
                    case 17017: // FIRAuthErrorCodeUserTokenExpired
                        print("User token expired - account may have been deleted")
                        completion(false)
                        return
                    default:
                        print("Other auth error - treating as invalid account")
                        completion(false)
                        return
                    }
                }
                
                // For any other error, assume account doesn't exist
                completion(false)
            } else if let _ = token {
                print("Successfully refreshed token - account exists on Firebase")
                // Token refresh successful, account exists
                completion(true)
            } else {
                print("No token returned - account likely doesn't exist")
                // No token returned, account doesn't exist
                completion(false)
            }
        }
    }
    
    // Clear authentication when user is deleted from Firebase but local token exists
    private func clearInvalidAuthentication() {
        DispatchQueue.main.async {
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            } catch {
                print("Error during invalid auth cleanup: \(error.localizedDescription)")
            }
            
            self.user = nil
            self.isAuthenticated = false
            
            // Clear all local data since user no longer exists
            self.clearAllLocalData()
            
            // Reset static flags
            AuthenticationManager.hasCompletedUserDetails = false
            AuthenticationManager.hasCompletedPropertyAddress = false
            AuthenticationManager.isCheckingUserStatus = false
            
            print("Cleared invalid authentication - user deleted from Firebase")
        }
    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.authError = error
                completion(false)
                return
            }
            
            // User signed in successfully
            if let user = authResult?.user {
                self.user = user
                self.isAuthenticated = true
                
                // Print user details and token to console
                self.printUserDetailsAndToken(user: user)
                
                // Check user status to determine which screen to show
                self.checkUserStatus {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
    }
    
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        print("Starting Google Sign-In process...")
        
        // Get the client ID from GoogleService-Info.plist directly
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: No Firebase client ID found")
            completion(false)
            return
        }
        
        // Create GIDConfiguration with the correct client ID
        let config = GIDConfiguration(clientID: clientID)
        
        print("Using Firebase client ID: \(clientID)")
        
        #if targetEnvironment(simulator)
        // Additional simulator-specific keychain reset
        print("Running on simulator - performing additional keychain reset before sign-in")
        SimulatorUtility.resetKeychain()
        
        // Set up keychain access group override for simulator
        print("Setting up keychain access group override for sign-in")
        KeychainAccessGroup.setupAccessGroup()
        #endif
        
        // Clear any existing keychain data that might be causing issues
        KeychainHelper.clearKeychain()
        
        // Start the sign in flow with the latest API
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] signInResult, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                self?.authError = error
                
                #if targetEnvironment(simulator)
                // On simulator, completely bypass authentication for testing
                print("Google Sign-In failed on simulator, using complete authentication bypass")
                
                // Use our authentication bypass for simulator
                SimulatorAuthFallback.bypassAuthentication { success in
                    if success {
                        // Create mock user
                        self?.mockUser = MockUser()
                        
                        // Set authenticated state without using keychain
                        self?.isAuthenticated = true
                        print("Successfully bypassed authentication for simulator testing")
                        
                        if let mockUser = self?.mockUser {
                            print("Mock user: \(mockUser.displayName)")
                        }
                        
                        // Continue with app flow
                        completion(true)
                    } else {
                        print("Failed to bypass authentication")
                        completion(false)
                    }
                }
                return
                #else
                // On real device, just report the error
                completion(false)
                return
                #endif
            }
            
            guard let signInResult = signInResult else {
                print("Error: Missing sign-in result")
                completion(false)
                return
            }
            
            let user = signInResult.user
            guard let idToken = user.idToken?.tokenString else {
                print("Error: Missing ID token")
                completion(false)
                return
            }
            
            print("Google Sign-In successful for user: \(user.profile?.email ?? "Unknown")")
            
            // Create Firebase credential with Google ID token
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase using the Google credential
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    self?.authError = error
                    
                    // Check for OAuth client ID mismatch error
                    let errorString = error.localizedDescription
                    if errorString.contains("audience") && errorString.contains("is not authorized") {
                        print("⚠️ OAuth client ID mismatch detected - using direct backend authentication")
                        
                        // Skip Firebase and call backend directly with the Google ID token
                        AuthService.shared.googleLogin(idToken: idToken) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let response):
                                    print("✅ Direct backend Google login successful")
                                    completion(true)
                                case .failure(let error):
                                    print("❌ Direct backend Google login failed: \(error.localizedDescription)")
                                    completion(false)
                                }
                            }
                        }
                        return
                    }
                    
                    // Handle other Firebase errors
                    completion(false)
                    return
                }
                
                print("Firebase authentication successful")
                // User is signed in
                if let user = authResult?.user {
                    self?.user = user
                    self?.isAuthenticated = true
                    
                    // Print user details and token to console
                    self?.printUserDetailsAndToken(user: user)
                    
                    completion(true)
                } else {
                    self?.isAuthenticated = true
                    completion(true)
                }
            }
        }
    }
    
    #if targetEnvironment(simulator)
    func bypassAuthenticationForSimulator(completion: @escaping (Bool) -> Void) {
        // Create mock user
        self.mockUser = MockUser()
        
        // Set authenticated state without using keychain
        self.isAuthenticated = true
        print("Successfully bypassed authentication for simulator testing")
        
        if let mockUser = self.mockUser {
            print("Mock user: \(mockUser.displayName)")
        }
        
        // Continue with app flow
        completion(true)
    }
    #endif
    
    // Permanently delete user account and all data
    func deleteUserAccount(completion: @escaping (Bool, Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        // Delete the Firebase user account
        user.delete { [weak self] error in
            if let error = error {
                print("Error deleting Firebase user: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            // Firebase user deleted successfully, now clear all local data
            self?.clearAllLocalData()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Reset authentication state
            self?.user = nil
            self?.isAuthenticated = false
            
            // Reset static flags
            AuthenticationManager.hasCompletedUserDetails = false
            AuthenticationManager.hasCompletedPropertyAddress = false
            AuthenticationManager.isCheckingUserStatus = false
            
            print("User account permanently deleted and all data cleared")
            completion(true, nil)
        }
    }
    
    // Clear all local storage data
    func clearAllLocalData() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        
        // Clear specific app data keys if they exist
        defaults.removeObject(forKey: "userDetails")
        defaults.removeObject(forKey: "propertyAddresses")
        defaults.removeObject(forKey: "rooms")
        defaults.removeObject(forKey: "entrancePhotos")
        defaults.synchronize()
        
        // Clear keychain data
        KeychainHelper.clearKeychain()
        
        print("All local data cleared")
    }
    
    // Force fresh app experience (useful for testing or reset)
    func resetAppToFreshState(completion: @escaping (Bool) -> Void) {
        // Sign out first
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Error signing out during reset: \(error.localizedDescription)")
        }
        
        // Clear all local data
        clearAllLocalData()
        
        // Reset authentication state
        self.user = nil
        self.isAuthenticated = false
        
        // Reset static flags
        AuthenticationManager.hasCompletedUserDetails = false
        AuthenticationManager.hasCompletedPropertyAddress = false
        AuthenticationManager.isCheckingUserStatus = false
        
        print("App reset to fresh state")
        completion(true)
    }
    
    func checkUserStatus(completion: @escaping () -> Void) {
        // Set flag to indicate we're checking user status
        AuthenticationManager.isCheckingUserStatus = true
        
        // Check if user details exist in local storage
        UserDetails.fetchFromLocalStorage { userDetails, error in
            if let _ = userDetails {
                AuthenticationManager.hasCompletedUserDetails = true
                
                // Check if property address exists
                PropertyAddress.fetchFromLocalStorage { addresses, error in
                    if let addresses = addresses, !addresses.isEmpty {
                        AuthenticationManager.hasCompletedPropertyAddress = true
                    } else {
                        AuthenticationManager.hasCompletedPropertyAddress = false
                    }
                    
                    // Reset flag when done checking
                    AuthenticationManager.isCheckingUserStatus = false
                    completion()
                }
            } else {
                AuthenticationManager.hasCompletedUserDetails = false
                AuthenticationManager.hasCompletedPropertyAddress = false
                
                // Reset flag when done checking
                AuthenticationManager.isCheckingUserStatus = false
                completion()
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    // Print user details and token to console
    func printUserDetailsAndToken(user: User) {
        print("\n==== FIREBASE AUTH SUCCESS ====")
        print("User ID: \(user.uid)")
        print("Email: \(user.email ?? "No email")")
        print("Display Name: \(user.displayName ?? "No display name")")
        print("Phone: \(user.phoneNumber ?? "No phone number")")
        print("Email Verified: \(user.isEmailVerified)")
        print("Creation Date: \(user.metadata.creationDate?.description ?? "Unknown")")
        print("Last Sign In: \(user.metadata.lastSignInDate?.description ?? "Unknown")")
        
        // Get the ID token
        user.getIDToken { token, error in
            if let error = error {
                print("Error getting token: \(error.localizedDescription)")
                return
            }
            
            if let token = token {
                print("\n==== AUTH TOKEN ====")
                print(token)
                print("\n==== END TOKEN ====")
            }
        }
        
        print("==== END USER DETAILS ====\n")
    }
}

// UIViewController representation for SwiftUI
struct GoogleSignInButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> GIDSignInButton {
        let button = GIDSignInButton()
        button.style = .wide
        button.colorScheme = .dark
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

// Extension to get the root view controller - iOS 14 compatible
extension UIApplication {
    class func getRootViewController() -> UIViewController {
        // iOS 14 compatible approach
        var rootViewController: UIViewController?
        
        // First try scene-based approach (iOS 13+)
        if #available(iOS 13.0, *) {
            rootViewController = UIApplication.shared.windows
                .filter { $0.isKeyWindow }
                .first?.rootViewController
        }
        
        // Fallback for older iOS versions or if scene-based approach failed
        if rootViewController == nil {
            rootViewController = UIApplication.shared.keyWindow?.rootViewController
        }
        
        // If still nil, create a new controller
        guard let controller = rootViewController else {
            return UIViewController()
        }
        
        // Find the presented view controller
        var topController = controller
        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
}
