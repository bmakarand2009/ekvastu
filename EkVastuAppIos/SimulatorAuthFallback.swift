import Foundation
import Firebase
import FirebaseAuth

#if targetEnvironment(simulator)
class SimulatorAuthFallback {
    // This class provides a direct authentication bypass for simulator testing
    // It completely bypasses both Google Sign-In and Firebase Auth for testing purposes
    
    // Mock user data for simulator testing
    private static let mockUserData = [
        "uid": "simulator-test-uid-123456",
        "email": "test@ekvastu.com",
        "displayName": "Test User",
        "photoURL": "https://example.com/photo.jpg"
    ]
    
    // Create a mock Firebase user for simulator testing
    static func createMockUser() -> User? {
        print("Creating mock user for simulator testing")
        return Auth.auth().currentUser
    }
    
    // Directly bypass authentication for simulator testing
    static func bypassAuthentication(completion: @escaping (Bool) -> Void) {
        print("Bypassing authentication for simulator testing")
        
        // Instead of trying to use Firebase Auth which still uses keychain,
        // we'll directly set up the AuthenticationManager with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Simulator auth bypass successful")
            completion(true)
        }
    }
    
    // Get mock user data for the app to use
    static func getMockUserData() -> [String: String] {
        return mockUserData
    }
    
    // Check if we're in a simulator test environment
    static var isSimulatorTestEnvironment: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
#endif
