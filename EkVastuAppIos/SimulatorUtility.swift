import Foundation
import Security

#if targetEnvironment(simulator)
class SimulatorUtility {
    static func resetKeychain() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secItemClass in secItemClasses {
            let query: [String: Any] = [kSecClass as String: secItemClass]
            SecItemDelete(query as CFDictionary)
        }
        
        // Set special simulator-only keychain settings
        setSimulatorKeychainSettings()
        
        print("Simulator keychain reset complete")
    }
    
    static func setSimulatorKeychainSettings() {
        // This is a special hack for simulator to bypass keychain access group restrictions
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        
        // Create a keychain query that will work on simulator
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "GoogleSignInTestAccount",
            kSecAttrService as String: bundleIdentifier,
            kSecValueData as String: "test_data".data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // First delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Then add a test item to initialize the keychain properly
        let status = SecItemAdd(query as CFDictionary, nil)
        print("Simulator keychain test item added with status: \(status)")
    }
}
#endif
