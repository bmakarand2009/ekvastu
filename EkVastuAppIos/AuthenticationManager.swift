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
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            self.user = user
            self.isAuthenticated = true
        }
    }
    
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        print("Starting Google Sign-In process...")
        
        // Get the client ID from Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            print("Error: No client ID found in Info.plist")
            completion(false)
            return
        }
        
        print("Using client ID: \(clientID)")
        
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
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
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
            
            guard let result = result else {
                print("Error: Missing sign-in result")
                completion(false)
                return
            }
            
            let user = result.user
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
                    completion(false)
                    return
                }
                
                print("Firebase authentication successful")
                // User is signed in
                self?.user = authResult?.user
                self?.isAuthenticated = true
                completion(true)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.authError = error
        }
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
