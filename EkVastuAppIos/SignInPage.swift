import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth


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
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
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
                        .frame(width: 300)
                        .padding(.top, 30)
                        
                        
                    }
                    .padding(.top, 40)
                    // Welcome text
                    Text("Welcome to EkShakti")
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
                                .foregroundColor(Color.white)
                               
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
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            
            // User signed in successfully
            if let user = authResult?.user {
                self.authManager.user = user
                self.authManager.isAuthenticated = true
                
                // Check user status to determine which screen to show
                self.authManager.checkUserStatus {
                    
                    self.isLoading = false
                    self.showHomeView = true
                }
            } else {
                self.isLoading = false
            }
        }
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
        
        // Start Google Sign-In flow
        authManager.signInWithGoogle(presenting: rootViewController) { success in
            if success {
                // Save user name from Google account to a new UserDetails object
                let userName = self.authManager.getUserDisplayName()
                let initialUserDetails = UserDetails(
                    name: userName,
                    dateOfBirth: Date(),
                    timeOfBirth: Date(),
                    placeOfBirth: ""
                )
                
                // Save initial user details to secure storage
                KeychainManager.saveUserDetails(initialUserDetails)
                
                // Always navigate to UserDetailsForm after successful Google sign-in
                // This ensures the user completes their profile with birth details
                AuthenticationManager.hasCompletedUserDetails = false
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showHomeView = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Google sign-in failed. Please try again."
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
    
    // Validation state
    @State private var emailError: String? = nil
    @State private var emailEdited = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo and brand
               HStack {
                       Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
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
        
        // Send password reset email using Firebase
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            self.isLoading = false
            
            if let error = error {
                self.message = "Error: \(error.localizedDescription)"
            } else {
                self.message = "Password reset link sent to your email"
                
                // Navigate back to sign in page after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct SignInPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignInPage()
        }
    }
    
}
