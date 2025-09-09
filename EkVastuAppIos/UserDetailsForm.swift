import SwiftUI
import Firebase
import UserNotifications
import FirebaseAuth

struct UserDetailsForm: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject private var profileManager = ProfileManager.shared
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
    
    // Profile states
    @State private var showProfileMessage = false
    @State private var profileMessage = ""
    @State private var isUpdatingProfile = false
    
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
    
    // Check if skip button should be enabled (only when profile exists)
    private var isSkipButtonEnabled: Bool {
        return profileManager.profileExists
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo and header
                    HStack {
                       Image("headerimage")
                        .frame(width: 78)
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
                    
                    // Profile status message
                    if showProfileMessage {
                        VStack(spacing: 10) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text(profileMessage)
                                    .font(.body)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Loading indicator for profile operations
                    if profileManager.isLoading || isUpdatingProfile {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(isUpdatingProfile ? "Updating profile..." : "Checking profile...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 10)
                    }
                    
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
                    
                    // Submit and Skip buttons
                    VStack(spacing: 15) {
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
                        .disabled(!isFormValid)
                        
                        // Skip button
                        Button(action: skipForm) {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(isSkipButtonEnabled ? Color(hex: "#4A2511") : Color.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSkipButtonEnabled ? Color(hex: "#4A2511") : Color.gray, lineWidth: 2)
                                        .fill(Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isSkipButtonEnabled)
                    }
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
                // Check profile from backend first
                checkProfileStatus()
                
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
            .onChange(of: profileManager.errorMessage) { errorMessage in
                if let errorMessage = errorMessage {
                    // Show profile not found message
                    profileMessage = errorMessage
                    showProfileMessage = true
                }
            }
            .onChange(of: profileManager.currentProfile) { profile in
                if let profile = profile, profileManager.profileExists {
                    // Profile exists, populate form with existing data
                    populateFormWithProfile(profile)
                    profileMessage = "Profile found! You can update your information below."
                    showProfileMessage = true
                }
            }
        }
    }
    
    // MARK: - Profile Management
    
    private func checkProfileStatus() {
        profileManager.checkAndLoadProfile()
    }
    
    private func populateFormWithProfile(_ profile: ProfileData) {
        // Parse and set date of birth
        let dobFormatter = DateFormatter()
        dobFormatter.dateFormat = "yyyy-MM-dd"
        if let dobDate = dobFormatter.date(from: profile.dob) {
            dateOfBirth = dobDate
            dateOfBirthText = dateFormatter.string(from: dobDate)
            validateDateOfBirth()
        }
        
        // Parse and set time of birth
        let timeFormatter24 = DateFormatter()
        timeFormatter24.dateFormat = "HH:mm:ss"
        if let timeDate = timeFormatter24.date(from: profile.timeOfBirth) {
            timeOfBirth = timeDate
            timeOfBirthText = timeFormatter.string(from: timeDate)
            validateTimeOfBirth()
        }
        
        // Set place of birth
        placeOfBirth = profile.placeOfBirth
        validatePlaceOfBirth()
        
        // Set name from profile
        name = profile.name
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
        isUpdatingProfile = true
        
        // Parse date and time from text fields
        guard let dateOfBirth = dateFormatter.date(from: dateOfBirthText),
              let timeOfBirth = timeFormatter.date(from: timeOfBirthText) else {
            isLoading = false
            isUpdatingProfile = false
            alertMessage = "Invalid date or time format"
            showAlert = true
            return
        }
        
        // Format date and time for API
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = apiDateFormatter.string(from: dateOfBirth)
        
        let apiTimeFormatter = DateFormatter()
        apiTimeFormatter.dateFormat = "HH:mm:ss"
        let timeString = apiTimeFormatter.string(from: timeOfBirth)
        
        // Check if profile exists to determine create vs update
        if profileManager.profileExists {
            // Update existing profile
            profileManager.updateProfile(
                placeOfBirth: placeOfBirth,
                timeOfBirth: timeString
            ) { success, message in
                DispatchQueue.main.async {
                    self.handleProfileOperationResult(success: success, message: message)
                }
            }
        } else {
            // Create new profile
            profileManager.createProfile(
                dob: dobString,
                placeOfBirth: placeOfBirth,
                timeOfBirth: timeString
            ) { success, message in
                DispatchQueue.main.async {
                    self.handleProfileOperationResult(success: success, message: message)
                }
            }
        }
    }
    
    private func handleProfileOperationResult(success: Bool, message: String?) {
        isLoading = false
        isUpdatingProfile = false
        
        if success {
            // Profile operation successful
            
            // Create or update user details object for local storage
            guard let dateOfBirth = dateFormatter.date(from: dateOfBirthText),
                  let timeOfBirth = timeFormatter.date(from: timeOfBirthText) else {
                return
            }
            
            let userName = existingUserDetails?.name ?? authManager.getUserDisplayName()
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
            
            // Hide profile message and show success
            showProfileMessage = false
            
            // Request notification permissions
            requestNotificationPermissions()
            
            // Navigate to property address list screen
            navigateToPropertyAddressList = true
            
        } else {
            // Profile operation failed
            alertMessage = message ?? "Failed to save profile. Please try again."
            showAlert = true
        }
    }
    
    private func skipForm() {
        // Mark user details as completed (skipped)
        AuthenticationManager.hasCompletedUserDetails = true
        
        // Always navigate to PropertyAddressListScreen
        // Users can use "Add new address" button to start adding properties
        print("Skipping user details, navigating to PropertyAddressListScreen")
        navigateToPropertyAddressList = true
    }
}


struct UserDetailsForm_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailsForm()
            .environmentObject(AuthenticationManager.shared)
    }
}
