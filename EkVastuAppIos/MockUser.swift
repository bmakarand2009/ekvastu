import Foundation
import Firebase
import FirebaseAuth

#if targetEnvironment(simulator)
class MockUser {
    // Mock user class for simulator testing
    
    // User profile data
    var uid: String
    var email: String
    var displayName: String
    var photoURL: URL?
    var isAuthenticated: Bool = true
    
    // Initialize with default test values
    init() {
        let userData = SimulatorAuthFallback.getMockUserData()
        self.uid = userData["uid"] ?? "simulator-test-uid"
        self.email = userData["email"] ?? "test@ekvastu.com"
        self.displayName = userData["displayName"] ?? "Test User"
        if let photoURLString = userData["photoURL"], let url = URL(string: photoURLString) {
            self.photoURL = url
        }
    }
    
    // Get user data as dictionary for use in the app
    func getUserData() -> [String: Any] {
        return [
            "uid": uid,
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL?.absoluteString ?? "",
            "isAuthenticated": isAuthenticated
        ]
    }
}
#endif
