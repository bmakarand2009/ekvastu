import Foundation
import Firebase
import FirebaseAuth
import SwiftUI
import CoreData

// Extension to AuthenticationManager to handle user information
extension AuthenticationManager {
    
    // Static properties to track user flow
    static var hasCompletedUserDetails = false
    static var hasCompletedPropertyAddress = false
    static var isCheckingUserStatus = true
    
    // Get user information for the app flow
    func getUserInfo() -> [String: Any]? {
        #if targetEnvironment(simulator)
        // For simulator testing, use mock user data if available
        if isAuthenticated, let mockUser = mockUser {
            return mockUser.getUserData()
        }
        #endif
        
        // For real device or if mock user is not available
        guard isAuthenticated, let user = user else { return nil }
        
        return [
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "photoURL": user.photoURL?.absoluteString ?? ""
        ]
    }
    
    // Get user display name
    func getUserDisplayName() -> String {
        #if targetEnvironment(simulator)
        if let mockUser = mockUser {
            return mockUser.displayName
        }
        #endif
        
        return user?.displayName ?? "User"
    }
    
    // Check if this is a first-time login
    func isFirstTimeLogin() -> Bool {
        return !Self.hasCompletedUserDetails
    }
    
    // Check user status after login
    func checkUserStatus(completion: @escaping () -> Void) {
        Self.isCheckingUserStatus = true
        
        // Always show onboarding for now - we're not using Firestore anymore
        // and will implement CoreData storage later
        self.isAuthenticated = false
        Self.hasCompletedUserDetails = false
        Self.hasCompletedPropertyAddress = false
        Self.isCheckingUserStatus = false
        
        // Short delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }
    
    // Get the appropriate view to show after login
    func getPostLoginView() -> AnyView {
        if !Self.hasCompletedUserDetails {
            // First-time user, show user details form
            return AnyView(UserDetailsForm())
        } else if !Self.hasCompletedPropertyAddress {
            // User has completed details but not property address
            return AnyView(PropertyAddressScreen())
        } else {
            // User has completed everything, show main content
            return AnyView(ContentView())
        }
    }
    
    // Helper method to determine which view to show without creating instances
    func getPostLoginViewType() -> PostLoginViewType {
        if !Self.hasCompletedUserDetails {
            return .userDetails
        } else if !Self.hasCompletedPropertyAddress {
            return .propertyAddress
        } else {
            return .mainContent
        }
    }
}

// Enum to represent the different post-login views
enum PostLoginViewType {
    case userDetails
    case propertyAddress
    case mainContent
}
