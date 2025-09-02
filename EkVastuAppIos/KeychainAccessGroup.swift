import Foundation
import Security

struct KeychainAccessGroup {
    static func setupAccessGroup() {
        #if targetEnvironment(simulator)
        // On simulator, we need to disable keychain access groups
        // This is a workaround for the SecItemCopyMatching (-34018) error
        setKeychainAccessGroupOverride()
        #endif
    }
    
    #if targetEnvironment(simulator)
    private static func setKeychainAccessGroupOverride() {
        // This is a special hack for simulator to bypass keychain access group restrictions
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        
        // Set the keychain access group to match the app's bundle ID
        let accessGroup = bundleIdentifier
        
        // Create the keychain access group override
        let key = "com.apple.keystore.access-group-prefix" as CFString
        let value = accessGroup as CFString
        UserDefaults.standard.set(value, forKey: key as String)
        UserDefaults.standard.synchronize()
        
        print("Simulator keychain access group override set to: \(accessGroup)")
    }
    #endif
}
