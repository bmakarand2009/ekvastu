import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import GoogleMaps
import GooglePlaces
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Enable debug logging
        print("=== App Launch: Starting Google Sign-In Debug ===")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Not found")")
        
        // Initialize Google Maps SDK
        // TODO: Replace with your actual Google Maps API key
        GMSServices.provideAPIKey("AIzaSyCiIbvc_BUCEiItFKPN9CUev3vmcCgmEZQ")
        GMSPlacesClient.provideAPIKey("AIzaSyCiIbvc_BUCEiItFKPN9CUev3vmcCgmEZQ")
        
        // Get client ID from Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            print("ERROR: GIDClientID not found in Info.plist")
            return false
        }
        
        print("GIDClientID from Info.plist: \(clientID)")
        
        // Clear keychain to resolve persistent issues
        print("Clearing keychain data for Google Sign-In")
        KeychainHelper.clearKeychain()
        
        #if targetEnvironment(simulator)
        // Additional simulator-specific keychain reset
        print("Running on simulator - performing additional keychain reset")
        SimulatorUtility.resetKeychain()
        
        // Set up keychain access group override for simulator
        print("Setting up keychain access group override for simulator")
        KeychainAccessGroup.setupAccessGroup()
        #endif
        
        // Configure Google Sign-In with proper initialization
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        print("Google Sign-In configured with client ID")
        
        // Try to restore previous sign-in
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Failed to restore previous sign-in: \(error.localizedDescription)")
            } else if let user = user {
                print("Successfully restored sign-in for user: \(user.profile?.email ?? "Unknown")")
            } else {
                print("No previous sign-in found")
            }
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
