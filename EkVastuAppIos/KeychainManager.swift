import Foundation
import Security
import Firebase
import FirebaseAuth

class KeychainManager {
    
    // Service name for the keychain items
    private static let serviceName = "com.ekvastu.userdetails"
    
    // Save UserDetails object to Keychain
    static func saveUserDetails(_ userDetails: UserDetails) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Convert UserDetails to Data
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(userDetails) else { return }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userId,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }
    
    // Load UserDetails object from Keychain
    static func loadUserDetails() -> UserDetails? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Search for the item
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Check if item was found
        guard status == errSecSuccess,
              let data = result as? Data,
              let userDetails = try? JSONDecoder().decode(UserDetails.self, from: data) else {
            return nil
        }
        
        return userDetails
    }
    
    // Update existing UserDetails in Keychain
    static func updateUserDetails(_ userDetails: UserDetails) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Convert UserDetails to Data
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(userDetails) else { return }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userId
        ]
        
        // Create update dictionary
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        // Update the item
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status != errSecSuccess {
            // If item doesn't exist, create it
            if status == errSecItemNotFound {
                saveUserDetails(userDetails)
            } else {
                print("Error updating Keychain: \(status)")
            }
        }
    }
    
    // Delete UserDetails from Keychain
    static func deleteUserDetails() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userId
        ]
        
        // Delete the item
        SecItemDelete(query as CFDictionary)
    }
}
