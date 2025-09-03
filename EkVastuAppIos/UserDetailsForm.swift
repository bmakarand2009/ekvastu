import SwiftUI
import Firebase
import UserNotifications
import FirebaseAuth

struct UserDetailsForm: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var name: String = ""
    @State private var dateOfBirthText = ""
    @State private var dateOfBirth = Date()
    @State private var timeOfBirthText = ""
    @State private var timeOfBirth = Date()
    @State private var placeOfBirth = ""
    
    // State for showing pickers
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    // Existing user details loaded from Keychain
    @State private var existingUserDetails: UserDetails?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToPropertyAddressList = false
    
    // Validation states
    @State private var dateOfBirthValid = false
    @State private var timeOfBirthValid = false
    @State private var placeOfBirthValid = false
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // Check if form is valid
    private var isFormValid: Bool {
        return dateOfBirthValid && timeOfBirthValid && placeOfBirthValid
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
                
                VStack(spacing: 20) {
                    // Logo and header
                    HStack {
                       Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .padding(.top, 30)
                        
                        
                    }
                    .padding(.top, 20)
                
                    // Title
                    Text("Personalized Weekly Updates")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("Stay aligned with your stars—weekly on\nWhatsApp/SMS")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                        .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 15) {
                        // Date of Birth field
                        Text("Date of Birth")
                            .font(.headline)
                        
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text(dateOfBirthText.isEmpty ? "Select date of birth" : dateOfBirthText)
                                    .foregroundColor(dateOfBirthText.isEmpty ? .gray : .black)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                        }.buttonStyle(.plain)
                        
                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: $dateOfBirth,
                                displayedComponents: .date
                            )
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .onChange(of: dateOfBirth) { newValue in
                                dateOfBirthText = dateFormatter.string(from: newValue)
                                validateDateOfBirth()
                            }
                            
                            Button("Done") {
                                showDatePicker = false
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color(hex: "#4A2511"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        // Time of Birth field
                        Text("Time of Birth")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        Button(action: {
                            showTimePicker = true
                        }) {
                            HStack {
                                Text(timeOfBirthText.isEmpty ? "Select time of birth" : timeOfBirthText)
                                    .foregroundColor(timeOfBirthText.isEmpty ? .gray : .black)
                                Spacer()
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                        }.buttonStyle(.plain)
                        
                        if showTimePicker {
                            DatePicker(
                                "",
                                selection: $timeOfBirth,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .onChange(of: timeOfBirth) { newValue in
                                timeOfBirthText = timeFormatter.string(from: newValue)
                                validateTimeOfBirth()
                            }
                            
                            Button("Done") {
                                showTimePicker = false
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color(hex: "#4A2511"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        // Place of Birth field
                        Text("Place of Birth")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        TextField("Enter place of birth", text: $placeOfBirth)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .onChange(of: placeOfBirth) { newValue in
                                validatePlaceOfBirth()
                            }
                    }
                    .padding(.horizontal)
                    
                    // Submit button
                    Button(action: submitForm) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isFormValid ? Color(hex: "#4A2511") : Color.gray)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    
                    NavigationLink(destination: PropertyAddressListScreen(), isActive: $navigateToPropertyAddressList) {
                        EmptyView()
                    }
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
            .onAppear {
                // Load existing user details from Keychain when view appears
                if let details = KeychainManager.loadUserDetails() {
                    existingUserDetails = details
                    name = details.name
                    
                    // Set date of birth
                    dateOfBirth = details.dateOfBirth
                    dateOfBirthText = dateFormatter.string(from: details.dateOfBirth)
                    validateDateOfBirth()
                    
                    // Set time of birth
                    timeOfBirth = details.timeOfBirth
                    timeOfBirthText = timeFormatter.string(from: details.timeOfBirth)
                    validateTimeOfBirth()
                    
                    // Set place of birth
                    placeOfBirth = details.placeOfBirth
                    validatePlaceOfBirth()
                }
            }
        }
    }
    
    // Validation functions
    private func validateDateOfBirth() {
        if dateOfBirthText.isEmpty {
            dateOfBirthValid = false
            return
        }
        
        // Check if date format is valid
        if let _ = dateFormatter.date(from: dateOfBirthText) {
            dateOfBirthValid = true
        } else {
            dateOfBirthValid = false
        }
    }
    
    private func validateTimeOfBirth() {
        if timeOfBirthText.isEmpty {
            timeOfBirthValid = false
            return
        }
        
        // Check if time format is valid
        if let _ = timeFormatter.date(from: timeOfBirthText) {
            timeOfBirthValid = true
        } else {
            timeOfBirthValid = false
        }
    }
    
    private func validatePlaceOfBirth() {
        placeOfBirthValid = !placeOfBirth.isEmpty
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    private func submitForm() {
        guard dateOfBirthValid && timeOfBirthValid && placeOfBirthValid else {
            alertMessage = "Please fill in all fields correctly"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Parse date and time from text fields
        guard let dateOfBirth = dateFormatter.date(from: dateOfBirthText),
              let timeOfBirth = timeFormatter.date(from: timeOfBirthText) else {
            isLoading = false
            alertMessage = "Invalid date or time format"
            showAlert = true
            return
        }
        
        // Create or update user details object
        // Preserve the name from Google sign-in if it exists
        let userName = existingUserDetails?.name ?? AuthenticationManager.shared.getUserDisplayName()
        
        let userDetails = UserDetails(
            name: userName,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            placeOfBirth: placeOfBirth
        )
        
        // Save to secure storage using Keychain
        KeychainManager.updateUserDetails(userDetails)
        
        // Update authentication manager state
        AuthenticationManager.hasCompletedUserDetails = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Request notification permissions
            requestNotificationPermissions()
            
            // Navigate to property address list screen
            navigateToPropertyAddressList = true
        }
    }
}


struct UserDetailsForm_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailsForm()
            .environmentObject(AuthenticationManager.shared)
    }
}
