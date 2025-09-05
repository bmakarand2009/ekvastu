import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseAuth

struct CreateAccountPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @Binding var showCreateAccount: Bool
    @State private var navigateToOnboarding = false
    
    // Authentication state
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var isLoading = false
    @State private var showHomeView = false
    
    // Validation state
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    
    // Track if fields have been edited
    @State private var nameEdited = false
    @State private var emailEdited = false
    @State private var passwordEdited = false
    
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
                
                // Welcome text
                Text("Welcome to EkShakti")
                    .font(.system(size: 24))
                    .padding(.top, 10)
                
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    SecureField("", text: $password)
                        .padding()
                        .background(Color(UIColor.systemBackground))
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
                
                // Already registered link with animation
                (Text("Already Registered? ")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white)
                    + Text("Sign in")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white))
                    .padding(.vertical)
                    .scaleEffect(signInPressed ? 1.2 : 1.0)
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
        return nameError == nil && emailError == nil && passwordError == nil && 
               !name.isEmpty && !email.isEmpty && !password.isEmpty && agreedToTerms
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
        validateName()
        validateEmail()
        validatePassword()
        
        return nameError == nil && emailError == nil && passwordError == nil && agreedToTerms
    }
    
    private func createAccount() {
        isLoading = true
        // Create user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            isLoading = false
            if let error = error {
                print("Error creating account: \(error.localizedDescription)")
                return
            }
            
            // User created successfully
            if let user = authResult?.user {
                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Error updating profile: \(error.localizedDescription)")
                    }
                }
                
                // Navigate to home view
                authManager.user = user
                authManager.isAuthenticated = true
                showHomeView = true
            }
        }
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        // Get the root view controller
        let rootViewController = UIApplication.getRootViewController()
        
        // Start Google Sign-In flow
        authManager.signInWithGoogle(presenting: rootViewController) { success in
             print(authManager)
            if success {
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
}


struct CreateAccountPage_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountPage(showCreateAccount: .constant(true))
    }
}
