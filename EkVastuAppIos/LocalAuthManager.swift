import SwiftUI

class LocalAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: LocalUser?
    @Published var authError: Error?
    
    static let shared = LocalAuthManager()
    
    private let userDefaultsKey = "localUsers"
    private let currentUserKey = "currentUser"
    
    init() {
        // Check if user is already signed in
        loadCurrentUser()
    }
    
    // MARK: - User Management
    
    struct LocalUser: Codable, Identifiable {
        let id: String
        let email: String
        let displayName: String
        var photoURL: String?
        
        init(id: String = UUID().uuidString, email: String, displayName: String, photoURL: String? = nil) {
            self.id = id
            self.email = email
            self.displayName = displayName
            self.photoURL = photoURL
        }
    }
    
    private func loadCurrentUser() {
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(LocalUser.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    private func saveCurrentUser() {
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: currentUserKey)
        }
    }
    
    private func getAllUsers() -> [LocalUser] {
        if let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let users = try? JSONDecoder().decode([LocalUser].self, from: userData) {
            return users
        }
        return []
    }
    
    private func saveAllUsers(_ users: [LocalUser]) {
        if let userData = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(userData, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // For simplicity, we're not handling passwords securely in this example
        // In a real app, you would use secure password hashing
        let users = getAllUsers()
        
        if let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) {
            self.currentUser = user
            self.isAuthenticated = true
            saveCurrentUser()
            completion(true)
        } else {
            self.authError = NSError(domain: "LocalAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            completion(false)
        }
    }
    
    func signUp(email: String, displayName: String, password: String, completion: @escaping (Bool) -> Void) {
        var users = getAllUsers()
        
        // Check if user already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            self.authError = NSError(domain: "LocalAuth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Email already in use"])
            completion(false)
            return
        }
        
        // Create new user
        let newUser = LocalUser(email: email, displayName: displayName)
        users.append(newUser)
        
        // Save to UserDefaults
        saveAllUsers(users)
        
        // Set as current user
        self.currentUser = newUser
        self.isAuthenticated = true
        saveCurrentUser()
        
        completion(true)
    }
    
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    // MARK: - User Profile
    
    func updateUserProfile(displayName: String? = nil, photoURL: String? = nil, completion: @escaping (Bool) -> Void) {
        guard var user = currentUser else {
            completion(false)
            return
        }
        
        if let displayName = displayName {
            user = LocalUser(id: user.id, email: user.email, displayName: displayName, photoURL: user.photoURL)
        }
        
        if let photoURL = photoURL {
            user = LocalUser(id: user.id, email: user.email, displayName: user.displayName, photoURL: photoURL)
        }
        
        // Update in users list
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveAllUsers(users)
        }
        
        // Update current user
        self.currentUser = user
        saveCurrentUser()
        
        completion(true)
    }
    
    // MARK: - Simulator Support
    
    #if targetEnvironment(simulator)
    func bypassAuthenticationForSimulator(completion: @escaping (Bool) -> Void) {
        let mockUser = LocalUser(email: "test@example.com", displayName: "Test User")
        self.currentUser = mockUser
        self.isAuthenticated = true
        saveCurrentUser()
        completion(true)
    }
    #endif
}

// MARK: - SwiftUI Button for Sign In
struct LocalSignInButton: View {
    let action: () -> Void
    let title: String
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
}
