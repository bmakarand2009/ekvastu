import Foundation
import Security

class KeychainHelper {
    static func clearKeychain() {
        // List of service names that might be used by Google Sign-In
        let serviceNames = ["com.google.GIDSignIn", "com.google.GoogleSignIn"]
        
        for service in serviceNames {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            
            // Delete all keychain items matching the service
            SecItemDelete(query as CFDictionary)
        }
        
        // Clear all keychain items for the app
        let appQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: "\(Bundle.main.bundleIdentifier ?? "org.ekshakti.EkVastu")"
        ]
        
        SecItemDelete(appQuery as CFDictionary)
        
        print("Keychain cleared for Google Sign-In")
    }
}
