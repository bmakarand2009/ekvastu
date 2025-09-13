import SwiftUI
import FirebaseAuth
import GoogleSignIn

class LogoutManager {
    static let shared = LogoutManager()
    
    private init() {}
    
    func logout(completion: @escaping () -> Void) {
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
        
        // Clear tokens on main thread
        DispatchQueue.main.async {
            TokenManager.shared.clearTokens()
            print("✓ Cleared tokens")
        }
        
        // Clear profile data on main thread
        DispatchQueue.main.async {
            ProfileManager.shared.clearProfile()
            print("✓ Cleared profile data")
        }
        
        // Reset authentication state in AuthenticationManager on main thread
        DispatchQueue.main.async {
            AuthenticationManager.shared.signOut()
            print("✓ Reset authentication state")
            
            // Clear any pending alerts
            NotificationCenter.default.post(name: NSNotification.Name("ClearAllAlerts"), object: nil)
            
            // Add a small delay to ensure all cleanup is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Call completion handler on main thread after everything is done
                completion()
            }
        }
    }
}
