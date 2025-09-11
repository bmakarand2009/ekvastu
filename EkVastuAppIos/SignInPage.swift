import SwiftUI
import Firebase
import GoogleSignIn


struct SignInPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @State private var showHomeView = false
    @State private var showForgotPassword = false
    @State private var showCreateAccount = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Validation state
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    // Track if fields have been edited
    @State private var emailEdited = false
    @State private var passwordEdited = false
    
    // Authentication state
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var authService = AuthService.shared
    
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
                        .frame(width: 78)
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
                        
                        TextField("", text: $email)
                            .padding()
                            .background(Color.white)
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
                
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        
                        SecureField("", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(passwordError != nil && passwordEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: password) { _ in
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
                        ).padding(.horizontal)
                    
                     

                    // Terms and conditions checkbox
                    HStack(alignment: .top) {
                      
                            ZStack {
                                Rectangle()
                                    .fill(agreedToTerms ? Color(hex: "#4A2511") : Color.white)
                                    .frame(width: 24, height: 24)
                                    .cornerRadius(4)
                                
                                if agreedToTerms {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        
                        
                        Text("By signing in, you agree to our Terms of Service & Privacy Policy")
                            .font(.system(size: 14))
                            .padding(.leading, 5)
                    }
                    .onTapGesture {
                        agreedToTerms.toggle()
                    }
                    
                
                    // Don't have an account link
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 16))
                        
                        NavigationLink(destination: CreateAccountPage(showCreateAccount: $showCreateAccount)) {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .bold))
                               
                               
                        }.buttonStyle(.plain)
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
            
            // Navigation to forgot password
            NavigationLink(destination: ForgotPasswordView(), isActive: $showForgotPassword) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: EmptyView())
    }
    
    private func formIsValid() -> Bool {
        return emailError == nil && passwordError == nil && 
               !email.isEmpty && !password.isEmpty && agreedToTerms
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
        // Trigger validation for all fields
        validateEmail()
        validatePassword()
        
        // Check if terms are agreed
        if !agreedToTerms {
            errorMessage = "Please agree to the Terms of Service & Privacy Policy"
            return false
        } else {
            errorMessage = nil
        }
        
        return emailError == nil && passwordError == nil && agreedToTerms
    }
    
    private func signInWithEmail() {
        guard formIsValid() else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Use backend API for authentication (automatically gets TID from tenant ping)
        authService.signIn(
            userId: email,
            password: password
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Backend authentication successful")
                    print("User: \(response.contact.fullName)")
                    print("Email: \(response.email)")
                    print("Role: \(response.role)")
                    
                    // Store user data locally
                    self.storeUserDataLocally(response: response)
                    
                    // Set authentication state
                    self.authManager.isAuthenticated = true
                    
                    // Navigate to appropriate screen
                    self.showHomeView = true
                    
                case .failure(let error):
                    print("❌ Backend authentication failed: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Store user data in local storage after successful backend authentication
    private func storeGoogleUserDataLocally(response: GoogleLoginResponse) {
        // Store tokens from backend response
        TokenManager.shared.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        // Store additional user info
        UserDefaults.standard.set(response.contact.id, forKey: "user_id")
        UserDefaults.standard.set(response.email, forKey: "user_email")
        UserDefaults.standard.set(response.contact.fullName, forKey: "user_name")
        UserDefaults.standard.set(response.contact.phone ?? "", forKey: "user_phone")
        UserDefaults.standard.set(response.role, forKey: "user_role")
        UserDefaults.standard.set(response.contact.picture ?? "", forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    private func storeUserDataLocally(response: SignInResponse) {
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
                print("✅ User details saved to local storage")
                
                // DO NOT mark user details as completed - force user to go through UserDetailsForm
                // This ensures user always sees UserDetailsForm after signin
                AuthenticationManager.hasCompletedUserDetails = false
            } else {
                print("❌ Failed to save user details: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        // Store authentication tokens using TokenManager
        TokenManager.shared.storeTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        // Store additional user info
        UserDefaults.standard.set(response.contact.id, forKey: "user_id")
        UserDefaults.standard.set(response.email, forKey: "user_email")
        UserDefaults.standard.set(response.contact.fullName, forKey: "user_name")
        UserDefaults.standard.set(response.contact.phone, forKey: "user_phone")
        UserDefaults.standard.set(response.role, forKey: "user_role")
        UserDefaults.standard.set(response.contact.picture, forKey: "user_picture")
        UserDefaults.standard.synchronize()
    }
    
    private func handleGoogleSignIn() {
        if !agreedToTerms {
            errorMessage = "Please agree to the Terms of Service & Privacy Policy"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Get the root view controller
        let rootViewController = UIApplication.getRootViewController()
        if rootViewController == nil {
            self.isLoading = false
            self.errorMessage = "Cannot present sign-in screen"
            return
        }
        
        // Use Firebase Google Sign-In
        authManager.signInWithGoogle(presenting: rootViewController) { success in
            if success {
                // Get the Firebase ID token
                self.authManager.user?.getIDToken { idToken, error in
                    if let idToken = idToken {
                        print("🔑 Got Firebase ID token, calling backend Google login...")
                        
                        // Call backend Google login API
                        AuthService.shared.googleLogin(idToken: idToken) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let response):
                                    print("✅ Backend Google login successful")
                                    
                                    // Store user data from backend response
                                    self.storeGoogleUserDataLocally(response: response)
                                    
                                    // Create initial user details in local storage
                                    let initialUserDetails = UserDetails(
                                        name: response.contact.fullName,
                                        dateOfBirth: Date(),
                                        timeOfBirth: Date(),
                                        placeOfBirth: ""
                                    )
                                    
                                    // Save to UserDefaults
                                    initialUserDetails.saveToLocalStorage { success, error in
                                        if !success {
                                            print("Failed to save initial user details: \(error?.localizedDescription ?? "Unknown error")")
                                        }
                                    }
                                    
                                    self.isLoading = false
                                    self.showHomeView = true
                                    
                                case .failure(let error):
                                    print("❌ Backend Google login failed: \(error.localizedDescription)")
                                    self.isLoading = false
                                    self.errorMessage = "Failed to authenticate with backend. Please try again."
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
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Google Sign-In failed. Please try again."
                }
            }
        }
    }
}

// ForgotPasswordView matching the provided design
struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var message: String? = nil
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var authManager = AuthenticationManager.shared
    
    // Validation state
    @State private var emailError: String? = nil
    @State private var emailEdited = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo and brand
               HStack {
                       Image("headerimage")
                       .frame(width: 78)
                        .padding(.top, 30)
                        
                    }
                    .padding(.top, 40)
                
                // Header text
                Text("Forgot your password")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                // Description text
                Text("Enter your email address and we will send you\na link to create a new password")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                
                // Email field label
                HStack {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Email input field
                TextField("", text: $email)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(emailError != nil && emailEdited ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
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
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
                
                // Send button
                Button(action: {
                    resetPassword()
                }) {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#4A2511"))
                        )
                }
                .padding(.horizontal)
                .disabled(!isEmailValid())
                .opacity(isEmailValid() ? 1.0 : 0.5)
                .padding(.top, 10)
                
                // Error/success message
                if let message = message {
                    Text(message)
                        .foregroundColor(message.contains("sent") ? .green : .red)
                        .padding()
                }
                
                Spacer()
                
           
                    Text("Back to Sign In")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                
            }
            .padding()
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: EmptyView())
    }
    
    private func isEmailValid() -> Bool {
        return emailError == nil && !email.isEmpty
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func resetPassword() {
        guard isEmailValid() else { return }
        
        isLoading = true
        message = nil
        
        // Use Firebase password reset
        authManager.resetPassword(email: email) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.message = "Error: \(error.localizedDescription)"
                } else {
                    self.message = "Password reset instructions sent to your email"
                    
                    // Navigate back to sign in page after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
 
