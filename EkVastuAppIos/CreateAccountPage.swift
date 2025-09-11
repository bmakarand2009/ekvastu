import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

struct CreateAccountPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var agreedToTerms: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @Binding var showCreateAccount: Bool
    @State private var navigateToOnboarding = false
    
    // Authentication state
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var authService = AuthService.shared
    @State private var isLoading = false
    @State private var showHomeView = false
    @State private var errorMessage: String? = nil
    
    // Validation state
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    
    // Track if fields have been edited
    @State private var nameEdited = false
    @State private var emailEdited = false
    
    // Animation state
    @State private var signInPressed = false
    @State private var navigateToSignIn = false
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Header image
                Image("headerimage")
                    .frame(width: 78)
                    .padding(.top, 30)
                
                 
                Text("Vastu by EkShakti")
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 20)
                
                Text("Create your account to begin your Vastu journey")
                    .font(.system(size: 16))
                     
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Form fields
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("", text: $name)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(nameError != nil && nameEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: name) { _ in
                            nameEdited = true
                            validateName()
                        }
                    
                    if let error = nameError, nameEdited {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("", text: $email)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(emailError != nil && emailEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { _ in
                            emailEdited = true
                            validateEmail()
                        }
                    
                    if let error = emailError, emailEdited {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                // Password field removed
                
                    Text("Sign up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            // Sign up button
                            if validateForm() {
                                createAccount()
                            }
                        }
                        .padding(20)
                        
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#3E2723"))
                        ).padding(.horizontal)
                
                
                .disabled(!formIsValid())
                .opacity(formIsValid() ? 1.0 : 0.5)
                
                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.subheadline)
                       
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)
                
               
                    HStack {
                        Image("google")
                            .resizable()
                            .frame(width: 24, height: 24)
                            
                        Text("Sign up with Google")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onTapGesture {
                        // Handle Google sign up
                        handleGoogleSignIn()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    ).padding(.horizontal)
                
                
 
                 // Terms and conditions checkbox
                HStack(alignment: .top) {
                   
                        ZStack {
                            Rectangle()
                                .fill(agreedToTerms ? Color(hex: "#333333") : Color.white)
                                .frame(width: 24, height: 24)
                                .cornerRadius(4)
                                .background(Color.clear)
                            
                            if agreedToTerms {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }.onTapGesture {
                            agreedToTerms.toggle()
                        }
                    
                    
                    Text("By signing in, you agree to our Terms of Service & Privacy Policy")
                        .font(.system(size: 14))
                        .padding(.leading, 5)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .padding(.horizontal)
                }
                
                // Already registered link with animation
                HStack {
                    Text("Already Registered? ")
                        .font(.system(size: 20, weight: .regular))
                    
                    Text("Sign in")
                        .font(.system(size: 20, weight: .bold))
                        .scaleEffect(signInPressed ? 1.2 : 1.0)
                }
                .padding(.vertical)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        signInPressed = true
                        
                        // Reset the animation after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    signInPressed = false
                                }
                                
                                // Navigate to SignInPage
                                navigateToSignIn = true
                            }
                        }
                    }
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: 
            Button(action: {
                // Always navigate back to onboarding page
                showCreateAccount = false
                // Post notification to ensure return to onboarding
                NotificationCenter.default.post(name: Notification.Name("ReturnToOnboarding"), object: nil)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        )
        .onDisappear {
            // Ensure we return to onboarding when this view disappears
            NotificationCenter.default.post(name: Notification.Name("ReturnToOnboarding"), object: nil)
        }
        
           
            
            // Navigation to appropriate view based on user status
            Group {
                if AuthenticationManager.isCheckingUserStatus {
                    // This is a placeholder - the actual navigation happens in checkUserStatus completion
                    EmptyView()
                } else if !AuthenticationManager.hasCompletedUserDetails {
                    NavigationLink(destination: UserDetailsForm(), isActive: $showHomeView) {
                        EmptyView()
                    }
                } else if !AuthenticationManager.hasCompletedPropertyAddress {
                    NavigationLink(destination: PropertyAddressScreen(), isActive: $showHomeView) {
                        EmptyView()
                    }
                } else {
                    NavigationLink(destination: ContentView(), isActive: $showHomeView) {
                        EmptyView()
                    }
                }
            }
            
            // Navigation to sign in page
            NavigationLink(destination: SignInPage(), isActive: $navigateToSignIn) {
                EmptyView()
            }
        }
    }
    
    private func formIsValid() -> Bool {
        return nameError == nil && emailError == nil && 
               !name.isEmpty && !email.isEmpty && agreedToTerms
    }
    
    private func validateName() {
        if name.isEmpty {
            nameError = "Name is required"
        } else {
            nameError = nil
        }
    }
    
    private func validateEmail() {
        if email.isEmpty {
            emailError = "Email is required"
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email"
        } else {
            emailError = nil
        }
    }
    
    // Password validation removed
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func validateForm() -> Bool {
        // Trigger validation for all fields
        validateName()
        validateEmail()
        
        return nameError == nil && emailError == nil && agreedToTerms
    }
    
    private func createAccount() {
        guard formIsValid() else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Use backend API for signup (automatically gets tenantId from tenant ping)
        authService.signUp(
            name: name,
            email: email
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        print("✅ Backend signup successful")
                        print("User: \(response.data?.name ?? "N/A")")
                        print("Email: \(response.data?.email ?? "N/A")")
                        
                        // Set authentication state
                        self.authManager.isAuthenticated = true
                        
                        // Navigate to appropriate screen
                        self.showHomeView = true
                    } else {
                        self.errorMessage = response.message ?? "Signup failed"
                    }
                    
                case .failure(let error):
                    // Extract user-friendly error message
                    let userFriendlyMessage = self.extractUserFriendlyErrorMessage(from: error)
                    print("❌ Backend signup failed: \(userFriendlyMessage)")
                    self.errorMessage = userFriendlyMessage
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        // Get the root view controller
        let rootViewController = UIApplication.getRootViewController()
        
        // Start Google Sign-In flow
        authManager.signInWithGoogle(presenting: rootViewController) { success in
            if success, let user = self.authManager.user {
                // Get the Firebase ID token
                user.getIDToken { idToken, error in
                    if let idToken = idToken {
                        print("🔑 Got Firebase ID token, calling backend Google signup...")
                        
                        // Call backend Google signup API
                        AuthService.shared.googleSignUp(idToken: idToken, user: user) { result in
                            DispatchQueue.main.async {
                                self.isLoading = false
                                
                                switch result {
                                case .success(let response):
                                    print("✅ Backend Google signup successful")
                                    
                                    // After successful signup, get tenant info and then call login
                                    self.performGoogleLoginAfterSignup(idToken: idToken)
                                    
                                case .failure(let error):
                                    print("❌ Backend Google signup failed: \(error.localizedDescription)")
                                    
                                    // If signup fails because user already exists, try login directly
                                    if error.localizedDescription.contains("already exists") {
                                        print("🔄 User already exists, trying Google login instead...")
                                        self.performGoogleLoginAfterSignup(idToken: idToken)
                                    } else {
                                        self.errorMessage = "Failed to sign up with Google. Please try again."
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("❌ Failed to get Firebase ID token: \(error?.localizedDescription ?? "Unknown error")")
                            self.isLoading = false
                            self.errorMessage = "Failed to get authentication token. Please try again."
                        }
                    }
                }
            } else {
                self.isLoading = false
                self.errorMessage = "Google Sign-In failed. Please try again."
            }
        }
    }
    
    private func performGoogleLoginAfterSignup(idToken: String) {
        print("🔑 Performing Google login after signup...")
        self.isLoading = true
        
        // Call backend Google login API
        AuthService.shared.googleLogin(idToken: idToken) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Backend Google login successful after signup")
                    
                    // Store user data from backend response
                    self.storeGoogleUserDataLocally(response: response)
                    
                    // Navigate to next screen
                    self.showHomeView = true
                    
                case .failure(let error):
                    print("❌ Backend Google login failed after signup: \(error.localizedDescription)")
                    self.errorMessage = "Failed to authenticate with backend. Please try again."
                }
            }
        }
    }
    
    private func performBackendSignupAfterGoogle() {
        // Get user info from Firebase after Google authentication
        guard let firebaseUser = authManager.user,
              let email = firebaseUser.email,
              let displayName = firebaseUser.displayName else {
            print("❌ Missing user info from Google authentication")
            self.isLoading = false
            self.errorMessage = "Failed to get user information from Google"
            return
        }
        
        print("🔐 Calling backend signup with Google user info:")
        print("   - Email: \(email)")
        print("   - Name: \(displayName)")
        
        // Call backend signup API with Google user info
        AuthService.shared.signUp(
            name: displayName,
            email: email
        ) { result in
            // Process result on main thread
            self.processSignUpResult(result: result, firebaseUser: firebaseUser)
        }
    }
    
    private func processSignUpResult(result: Result<SignUpResponse, NetworkError>, firebaseUser: User) {
        let work = DispatchWorkItem {
            self.isLoading = false
            
            switch result {
            case .success(let response):
                print("✅ Backend signup successful after Google authentication")
                
                // SignUpResponse doesn't have tokens - just proceed
                // Tokens are only returned in SignInResponse
                
                // Store user data locally
                self.storeGoogleUserDataLocally(response: response, googleUser: firebaseUser)
                
                // Navigate to next screen
                self.showHomeView = true
                
            case .failure(let error):
                print("❌ Backend signup failed after Google authentication: \(error)")
                
                // Check if user already exists, then try signin instead
                if error.localizedDescription.contains("already exists") || 
                   error.localizedDescription.contains("Contact with email already exists") {
                    print("🔄 User exists, attempting signin instead...")
                    self.performBackendSigninAfterGoogle(email: firebaseUser.email ?? "")
                } else {
                    self.errorMessage = self.extractUserFriendlyErrorMessage(from: error)
                }
            }
        }
        
        DispatchQueue.main.async(execute: work)
    }
    
    private func performBackendSigninAfterGoogle(email: String) {
        // If signup fails because user exists, try signin
        AuthService.shared.signIn(
            userId: email,
            password: "google_auth_placeholder" // This won't work, but we'll handle the error
        ) { result in
            // Process result on main thread
            self.processSignInResult(result: result)            
        }
    }
    
    private func processSignInResult(result: Result<SignInResponse, NetworkError>) {
        let work = DispatchWorkItem {
            switch result {
            case .success(let response):
                print("✅ Backend signin successful after Google authentication")
                
                // Store tokens from backend response
                TokenManager.shared.storeTokens(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
                
                // Navigate to next screen
                self.showHomeView = true
                
            case .failure(_):
                // If signin also fails, just proceed with Firebase auth only
                print("ℹ️ Backend signin failed, proceeding with Firebase-only authentication")
                self.showHomeView = true
            }
        }
        
        DispatchQueue.main.async(execute: work)
    }
    
    private func storeGoogleUserDataLocally(response: GoogleLoginResponse) {
        // Store tokens from backend response
        TokenManager.shared.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        // Create UserDetails object from backend response
        let userDetails = UserDetails(
            name: response.contact.fullName,
            dateOfBirth: Date(), // Default value, can be updated later
            timeOfBirth: Date(), // Default value, can be updated later
            placeOfBirth: "" // Default value, can be updated later
        )
        
        // Save to local storage
        userDetails.saveToLocalStorage { success, error in
            if success {
                print("✅ Google user details saved to local storage")
            } else {
                print("❌ Failed to save Google user details: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Store additional user info
        UserDefaults.standard.set(response.contact.id, forKey: "user_id")
        UserDefaults.standard.set(response.email, forKey: "user_email")
        UserDefaults.standard.set(response.contact.fullName, forKey: "user_name")
        UserDefaults.standard.set(response.contact.phone ?? "", forKey: "user_phone")
        UserDefaults.standard.set(response.role, forKey: "user_role")
        UserDefaults.standard.set(response.contact.picture ?? "", forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    private func storeGoogleUserDataLocally(response: SignUpResponse, googleUser: User) {
        // Create UserDetails object from Google user info
        let userDetails = UserDetails(
            name: googleUser.displayName ?? response.data?.name ?? "User",
            dateOfBirth: Date(), // Default value, can be updated later
            timeOfBirth: Date(), // Default value, can be updated later
            placeOfBirth: "" // Default value, can be updated later
        )
        
        // Save to local storage
        userDetails.saveToLocalStorage { success, error in
            if success {
                print("✅ Google user details saved to local storage")
            } else {
                print("❌ Failed to save Google user details: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Store additional user info
        UserDefaults.standard.set(response.data?.id ?? "", forKey: "user_id")
        UserDefaults.standard.set(response.data?.email ?? "", forKey: "user_email")
        UserDefaults.standard.set(googleUser.displayName ?? response.data?.name ?? "", forKey: "user_name")
        UserDefaults.standard.set(googleUser.phoneNumber ?? "", forKey: "user_phone")
        UserDefaults.standard.set(response.data?.status ?? "", forKey: "user_role")
        UserDefaults.standard.set(googleUser.photoURL?.absoluteString ?? "", forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Helper Methods
    private func extractUserFriendlyErrorMessage(from error: NetworkError) -> String {
        switch error {
        case .serverError(let statusCode, let errorMessage):
            // Try to parse the nested error structure
            if let errorData = errorMessage?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
               let errors = json["errors"] as? [String: Any],
               let messageString = errors["message"] as? String {
                
                // The message itself might be a JSON string, try to parse it
                if let messageData = messageString.data(using: .utf8),
                   let messageJson = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
                   let actualMessage = messageJson["message"] as? String {
                    return actualMessage
                }
                
                // If not nested JSON, return the message string as is
                return messageString
            }
            
            // Fallback to original error message
            return errorMessage ?? "Server error (\(statusCode))"
            
        default:
            return error.localizedDescription
        }
    }
}
 
