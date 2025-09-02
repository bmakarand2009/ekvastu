import SwiftUI
import Firebase

struct UserDetailsForm: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var name: String
    @State private var dateOfBirth = Date()
    @State private var timeOfBirth = Date()
    @State private var placeOfBirth = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToPropertyAddress = false
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    init() {
        // Pre-populate name with Google account name if available
        let displayName = AuthenticationManager.shared.getUserDisplayName()
        _name = State(initialValue: displayName)
    }
    
    var body: some View {
        NavigationView {
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
                        // App logo
                        Image("ekshakti")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(.top, 20)
                        
                        Text("User Details")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                        
                        // Form fields
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Name")
                                .font(.headline)
                            
                            TextField("Enter your name", text: $name)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("Date of Birth")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            DatePicker("Select Date", selection: $dateOfBirth, displayedComponents: .date)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                            
                            Text("Time of Birth")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            DatePicker("Select Time", selection: $timeOfBirth, displayedComponents: .hourAndMinute)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                            
                            Text("Place of Birth")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            TextField("Enter place of birth", text: $placeOfBirth)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Submit button
                        Button(action: submitForm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "#8B4513"))
                                    .frame(height: 50)
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Submit")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .disabled(name.isEmpty || placeOfBirth.isEmpty || isLoading)
                        
                        NavigationLink(
                            destination: PropertyAddressScreen(),
                            isActive: $navigateToPropertyAddress,
                            label: { EmptyView() }
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func submitForm() {
        guard !name.isEmpty, !placeOfBirth.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create user details object
        let userDetails = UserDetails(
            name: name,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            placeOfBirth: placeOfBirth
        )
        
        // Save to Firestore
        userDetails.saveToFirestore { success, error in
            isLoading = false
            
            if success {
                // Navigate to property address screen
                navigateToPropertyAddress = true
            } else {
                alertMessage = error?.localizedDescription ?? "Failed to save user details"
                showAlert = true
            }
        }
    }
}

struct UserDetailsForm_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailsForm()
            .environmentObject(AuthenticationManager.shared)
    }
}
