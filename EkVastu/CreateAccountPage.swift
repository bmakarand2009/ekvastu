import SwiftUI

struct CreateAccountPage: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var agreedToTerms: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @Binding var showCreateAccount: Bool
    
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Header image
                Image("headerimage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
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
                        .onChange(of: name) { oldValue, newValue in
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
                        .onChange(of: email) { oldValue, newValue in
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
                
                
                // Sign up button
                Button(action: {
                    // Handle sign up
                    if validateForm() {
                        createAccount()
                    }
                }) {
                    Text("Sign up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#3E2723"))
                        )
                }
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
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)
                
                // Google sign up button
                Button(action: {
                    // Handle Google sign up
                }) {
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                }
                .padding(.horizontal)

                 // Terms and conditions checkbox
                HStack(alignment: .top) {
                    Button(action: {
                        agreedToTerms.toggle()
                    }) {
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
                        }
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
                            }
                        }
                        print("click sign in")
                    }
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: 
            Button(action: {
                // Navigate back to onboarding page
                showCreateAccount = false
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        )
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
        // Here you would implement the actual account creation logic
        // For now, we'll just print the values
        print("Creating account with name: \(name), email: \(email)")
    }
}


struct CreateAccountPage_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountPage(showCreateAccount: .constant(true))
    }
}
