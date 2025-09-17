import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

struct SignInPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showHomeView = false
    @State private var showForgotPassword = false
    @State private var showCreateAccount = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    // Validation state
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    // Track if fields have been edited
    @State private var emailEdited = false
    @State private var passwordEdited = false
    
    // Authentication state
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    // NEW: Flag to prevent auto-navigation during Google Sign-In process
    @State private var isProcessingGoogleSignIn = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and header
                    HStack {
                       Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.top, 30)
                    }
                    .padding(.top, 40)
                    
                    // Welcome text
                    Text("Vastu by EkShakti")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 20)
                    
                    Text("Sign in to begin your Vastu journey")
                        .font(.system(size: 16))
                        .padding(.bottom, 20)
                
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        
                        TextField("Enter email", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(emailError != nil && emailEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .accentColor(.black)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { oldValue, newValue in
                                emailEdited = true
                                validateEmail()
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                        
                        if let error = emailError, emailEdited {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        
                        SecureField("Enter password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordError != nil && passwordEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .accentColor(.black)
                            .onChange(of: password) { oldValue, newValue in
                                passwordEdited = true
                                validatePassword()
                            }
                        
                        if let error = passwordError, passwordEdited {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                
                    // Forgot password link
                    HStack {
                        Spacer()
                        Text("Forgot Password?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#4A2511"))
                            .onTapGesture {
                                showForgotPassword = true
                            }
                    }
                    .padding(.horizontal)
                
                    // Sign In button
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .onTapGesture {
                            if validateForm() {
                                signInWithEmail()
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#4A2511"))
                        )
                        .padding(.horizontal)
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
                
                    // Google sign in button
                    HStack {
                        Image("google")
                            .resizable()
                            .frame(width: 24, height: 24)
                            
                        Text("Sign in with Google")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .onTapGesture {
                        handleGoogleSignIn()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                    .padding(.horizontal)
                    
                    // Don't have an account link
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 16))
                        
                        NavigationLink(destination: CreateAccountPage(showCreateAccount: $showCreateAccount)) {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 20)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            
            // FIXED: Only navigate when explicitly allowed and not processing Google Sign-In
            Group {
                if AuthenticationManager.isCheckingUserStatus {
                    EmptyView()
                } else {
                    EmptyView()
                        .navigationDestination(isPresented: Binding<Bool>(
                            get: {
                                // Only allow navigation if we're not processing Google Sign-In
                                // and showHomeView is true
                                return showHomeView && !isProcessingGoogleSignIn
                            },
                            set: { newValue in
                                showHomeView = newValue
                            }
                        )) {
                            UserDetailsForm()
                        }
                }
            }
            
            // Navigation to forgot password
            EmptyView()
                .navigationDestination(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: EmptyView())
        .alert("Login Error", isPresented: $showErrorAlert) {
            Button("OK") {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An error occurred during login. Please try again.")
        }
        // FIXED: Override auth state changes during Google Sign-In process
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            // If we're processing Google Sign-In and auth state changes to true,
            // don't automatically navigate - wait for backend validation
            if isProcessingGoogleSignIn && isAuthenticated {
                print("🚫 Preventing auto-navigation during Google Sign-In backend validation")
                // Reset the auth state to prevent automatic navigation
                DispatchQueue.main.async {
                    authManager.isAuthenticated = false
                }
            }
        }
    }
    
    private func formIsValid() -> Bool {
        return emailError == nil && passwordError == nil &&
               !email.isEmpty && !password.isEmpty
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
    
    private func validatePassword() {
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func validateForm() -> Bool {
        validateEmail()
        validatePassword()
        return emailError == nil && passwordError == nil
    }
    
    private func signInWithEmail() {
        guard formIsValid() else { return }
        
        isLoading = true
        errorMessage = nil
        
        authService.emailLogin(
            email: email,
            password: password
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Email login successful")
                    self.storeUserDataLocally(response: response)
                    self.authManager.isAuthenticated = true
                    self.showHomeView = true
                    
                case .failure(let error):
                    print("❌ Email login failed: \(error.localizedDescription)")
                    
                    switch error {
                    case .serverError(let code, let message):
                        if code == 201, let message = message, message.contains("invalid email and password") {
                            self.errorMessage = "Invalid email or password. Please check your credentials and try again."
                        } else {
                            self.errorMessage = "Server error (\(code)): \(message ?? "Unknown error")"
                        }
                    case .unauthorized:
                        self.errorMessage = "Invalid email or password. Please check your credentials and try again."
                    case .networkError(_):
                        self.errorMessage = "Network connection issue. Please check your internet connection."
                    case .timeout:
                        self.errorMessage = "Connection timed out. Please try again later."
                    default:
                        self.errorMessage = "Login failed. Please try again."
                    }
                    
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func storeGoogleUserDataLocally(response: GoogleLoginResponse) {
        TokenManager.shared.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        UserDefaults.standard.set(response.contact.id, forKey: "user_id")
        UserDefaults.standard.set(response.email, forKey: "user_email")
        UserDefaults.standard.set(response.contact.fullName, forKey: "user_name")
        UserDefaults.standard.set(response.contact.phone ?? "", forKey: "user_phone")
        UserDefaults.standard.set(response.role, forKey: "user_role")
        UserDefaults.standard.set(response.contact.picture ?? "", forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    private func extractEmailFromErrorMessage(_ message: String) -> String {
        if let range = message.range(of: "for email ") {
            let emailPart = String(message[range.upperBound...])
            let email = emailPart.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?"))
            return email
        }
        return "this email"
    }
    
    private func storeUserDataLocally(response: SignInResponse) {
        let userDetails = UserDetails(
            name: response.contact.fullName,
            dateOfBirth: Date(),
            timeOfBirth: Date(),
            placeOfBirth: ""
        )
        
        userDetails.saveToLocalStorage { success, error in
            if success {
                print("✅ User details saved to local storage")
                AuthenticationManager.hasCompletedUserDetails = false
            } else {
                print("❌ Failed to save user details: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        TokenManager.shared.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        UserDefaults.standard.set(response.contact.id, forKey: "user_id")
        UserDefaults.standard.set(response.email, forKey: "user_email")
        UserDefaults.standard.set(response.contact.fullName, forKey: "user_name")
        UserDefaults.standard.set(response.contact.phone, forKey: "user_phone")
        UserDefaults.standard.set(response.role, forKey: "user_role")
        UserDefaults.standard.set(response.contact.picture, forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    private func handleGoogleSignIn() {
        // FIXED: Set processing flag to prevent auto-navigation
        isProcessingGoogleSignIn = true
        isLoading = true
        errorMessage = nil
        
        let rootViewController = UIApplication.getRootViewController()
        
        authManager.signInWithGoogle(presenting: rootViewController) { success in
            if success {
                self.authManager.user?.getIDToken { idToken, error in
                    if let idToken = idToken {
                        print("🔑 Got Firebase ID token, calling backend Google login...")
                        
                        AuthService.shared.googleLogin(idToken: idToken) { result in
                            DispatchQueue.main.async {
                                // FIXED: Always reset processing flag
                                self.isProcessingGoogleSignIn = false
                                
                                switch result {
                                case .success(let response):
                                    print("✅ Backend Google login successful")
                                    
                                    self.storeGoogleUserDataLocally(response: response)
                                    
                                    let initialUserDetails = UserDetails(
                                        name: response.contact.fullName,
                                        dateOfBirth: Date(),
                                        timeOfBirth: Date(),
                                        placeOfBirth: ""
                                    )
                                    
                                    initialUserDetails.saveToLocalStorage { success, error in
                                        if !success {
                                            print("Failed to save initial user details: \(error?.localizedDescription ?? "Unknown error")")
                                        }
                                    }
                                    
                                    // FIXED: Only set auth state after successful backend validation
                                    self.authManager.isAuthenticated = true
                                    self.isLoading = false
                                    self.showHomeView = true
                                    
                                case .failure(let error):
                                    print("❌ Backend Google login failed: \(error.localizedDescription)")
                                    self.isLoading = false
                                    
                                    // FIXED: Sign out from Firebase to prevent auth state conflicts
                                    try? Auth.auth().signOut()
                                    self.authManager.isAuthenticated = false
                                    
                                    // FIXED: Enhanced error messaging for signup guidance
                                    switch error {
                                    case .serverError(let code, let message):
                                        if code == 500, let message = message, message.contains("Google services file not found") {
                                            self.errorMessage = "Google login is not configured on the server. Please try email login instead."
                                        } else if code == 500, let message = message, message.contains("no valid contact found") {
                                            let email = self.extractEmailFromErrorMessage(message)
                                            self.errorMessage = "No account found for \(email). Please create an account first by tapping 'Sign up' below."
                                            
                                            // Post notification to inform OnboardingView about this specific error
                                            NotificationCenter.default.post(
                                                name: Notification.Name("GoogleLoginNoValidContactError"),
                                                object: nil,
                                                userInfo: ["errorMessage": "No valid account found for \(email). Please create an account first."]
                                            )
                                            
                                            // Navigate back to onboarding
                                            NotificationCenter.default.post(name: Notification.Name("ReturnToOnboarding"), object: nil)
                                        } else {
                                            self.errorMessage = "Server error (\(code)): \(message ?? "Unknown error")"
                                        }
                                    case .unauthorized:
                                        self.errorMessage = "Authentication failed. Please try again or use email login."
                                    case .networkError(_):
                                        self.errorMessage = "Network connection issue. Please check your internet connection."
                                    case .timeout:
                                        self.errorMessage = "Connection timed out. Please try again later."
                                    default:
                                        self.errorMessage = "Failed to authenticate with backend. Please try again."
                                    }
                                    
                                    self.showErrorAlert = true
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            // FIXED: Reset processing flag on token error
                            self.isProcessingGoogleSignIn = false
                            print("❌ Failed to get Firebase ID token: \(error?.localizedDescription ?? "Unknown error")")
                            self.isLoading = false
                            
                            // FIXED: Sign out from Firebase
                            try? Auth.auth().signOut()
                            self.authManager.isAuthenticated = false
                            
                            self.errorMessage = "Failed to get authentication token. Please try again."
                            self.showErrorAlert = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    // FIXED: Reset processing flag on Google Sign-In failure
                    self.isProcessingGoogleSignIn = false
                    self.isLoading = false
                    self.authManager.isAuthenticated = false
                    self.errorMessage = "Google Sign-In failed. Please try again."
                    self.showErrorAlert = true
                }
            }
        }
    }
}
