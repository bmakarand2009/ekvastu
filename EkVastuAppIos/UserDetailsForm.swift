import SwiftUI
import Firebase
import UserNotifications
import FirebaseAuth
// LogoutManager is a file in the project, not a module

struct UserDetailsForm: View {
    // Force refresh parameter to ensure profile API is called when navigating back
    var forceRefresh: Bool = false
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
    @State private var navigateToOnboarding = false
    
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
                
                VStack(spacing: 0) {
                    // Fixed header
                    HStack {
                        Spacer()
                        
                        Image("headerimage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.top, 30)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Scrollable content
                    ScrollView(showsIndicators: true) {
                        VStack(spacing: 20) {
                            // Title
                            Text("Personalized Weekly Updates")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                            
                            Text("Stay aligned with your stars—weekly on WhatsApp/SMS")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 5)
                                .padding(.bottom, 20)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
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
                                }
                                .padding(.horizontal)
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
                            
                            // Sign Out Button
                            Button(action: {
                                alertMessage = "Are you sure you want to logout?"
                                showAlert = true
                            }) {
                                Text("Sign Out")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Add padding at the bottom to ensure content doesn't get cut off
                            Spacer().frame(height: 50)
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                if alertMessage == "Are you sure you want to logout?" {
                    return Alert(
                        title: Text("Logout"),
                        message: Text("Are you sure you want to logout?"),
                        primaryButton: .destructive(Text("Logout")) {
                            // Perform logout with complete data cleanup
                            LogoutManager.shared.logout {
                                // Navigate to onboarding screen after logout
                                navigateToOnboarding = true
                            }
                        },
                        secondaryButton: .cancel()
                    )
                } else {
                    return Alert(
                        title: Text("Message"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .onAppear {
                print("🔄 UserDetailsForm appeared, forceRefresh: \(forceRefresh)")
                
                // Always check profile from backend first
                checkProfileStatus()
                
                // Load existing user details from Keychain when view appears
                loadUserDetailsFromKeychain()
                
                // Force refresh profile data if needed
                if forceRefresh {
                    print("🔄 Forcing profile refresh from API")
                    // Add a slight delay to ensure view is fully presented
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        profileManager.checkAndLoadProfile()
                    }
                }
            }
            .onReceive(profileManager.$currentProfile) { profile in
                print("💬 Profile data received: \(profile != nil ? "yes" : "no")")
                if let profile = profile {
                    print("💬 Populating form with profile: \(profile.name), DOB: \(profile.dob), TOB: \(profile.timeOfBirth)")
                    populateFormWithProfile(profile)
                }
            }
            
            // Add fullScreenCover for navigation to onboarding
            .fullScreenCover(isPresented: $navigateToOnboarding) {
                OnboardingView()
                    .environmentObject(authManager)
            }
            .onChange(of: profileManager.errorMessage) { errorMessage in
                if let errorMessage = errorMessage {
                    // Show profile not found message
                    profileMessage = errorMessage
                    showProfileMessage = true

                    // If not authenticated, attempt to refresh backend tokens using Firebase user
                    if errorMessage == "Not authenticated" {
                        if let firebaseUser = authManager.user {
                            firebaseUser.getIDToken { idToken, _ in
                                if let idToken = idToken {
                                    AuthService.shared.googleLogin(idToken: idToken) { result in
                                        DispatchQueue.main.async {
                                            switch result {
                                            case .success:
                                                // Tokens should be stored by AuthService; retry profile check
                                                profileManager.checkAndLoadProfile()
                                            case .failure:
                                                // Keep showing the message; user can try again or logout
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: profileManager.currentProfile) { profile in
                if let profile = profile, profileManager.profileExists {
                    // Profile exists, populate form with existing data
                    populateFormWithProfile(profile)
                    // Do not show banner when profile exists and fields are populated
                    showProfileMessage = false
                }
            }
        }
    }
    
    // MARK: - Profile Management
    
    private func checkProfileStatus() {
        print("🔄 Checking profile status... forceRefresh: \(forceRefresh)")
        profileManager.checkAndLoadProfile()
    }
    
    // Load user details from Keychain
    private func loadUserDetailsFromKeychain() {
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
            
            print("✅ Loaded user details from Keychain: \(details.name), DOB: \(dateOfBirthText), TOB: \(timeOfBirthText)")
        } else {
            print("⚠️ No user details found in Keychain")
        }
    }
    
    private func populateFormWithProfile(_ profile: ProfileData) {
        print("💬 POPULATING FORM with profile data")
        
        // Parse and set date of birth
        let dobFormatter = DateFormatter()
        dobFormatter.dateFormat = "yyyy-MM-dd"
        if let dobDate = dobFormatter.date(from: profile.dob) {
            dateOfBirth = dobDate
            dateOfBirthText = dateFormatter.string(from: dobDate)
            validateDateOfBirth()
            print("💬 Set DOB: \(dateOfBirthText)")
        } else {
            print("⚠️ Failed to parse DOB: \(profile.dob)")
        }
        
        // Parse and set time of birth
        let timeFormatter24 = DateFormatter()
        timeFormatter24.dateFormat = "HH:mm:ss"
        if let timeDate = timeFormatter24.date(from: profile.timeOfBirth) {
            timeOfBirth = timeDate
            timeOfBirthText = timeFormatter.string(from: timeDate)
            validateTimeOfBirth()
            print("💬 Set TOB: \(timeOfBirthText)")
        } else {
            print("⚠️ Failed to parse TOB: \(profile.timeOfBirth)")
        }
        
        // Set place of birth
        placeOfBirth = profile.placeOfBirth
        validatePlaceOfBirth()
        print("💬 Set Place of Birth: \(placeOfBirth)")
        
        // Set name from profile
        name = profile.name
        print("💬 Set Name: \(name)")
        
        // Save to keychain to ensure data persistence
        saveToKeychain(profile: profile)
        
        // Update validation state to enable submit button
        dateOfBirthValid = true
        timeOfBirthValid = true
        placeOfBirthValid = true
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
    
    // Save profile data to keychain for persistence
    private func saveToKeychain(profile: ProfileData) {
        // Create date objects from strings
        let dobFormatter = DateFormatter()
        dobFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter24 = DateFormatter()
        timeFormatter24.dateFormat = "HH:mm:ss"
        
        guard let dobDate = dobFormatter.date(from: profile.dob),
              let timeDate = timeFormatter24.date(from: profile.timeOfBirth) else {
            print("⚠️ Failed to parse dates for keychain storage")
            return
        }
        
        // Create UserDetails object
        let userDetails = UserDetails(
            name: profile.name,
            dateOfBirth: dobDate,
            timeOfBirth: timeDate,
            placeOfBirth: profile.placeOfBirth
        )
        
        // Save to keychain
        KeychainManager.updateUserDetails(userDetails)
        print("✅ Saved profile data to keychain")
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
        
        // Ensure backend tokens exist; if not, refresh via Firebase ID token then proceed
        if !TokenManager.shared.hasValidToken() {
            if let firebaseUser = authManager.user {
                firebaseUser.getIDToken { idToken, _ in
                    if let idToken = idToken {
                        AuthService.shared.googleLogin(idToken: idToken) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    // After obtaining tokens, retry submission by calling submitForm() again
                                    self.isLoading = false
                                    self.isUpdatingProfile = false
                                    // Call submit again on next runloop to avoid recursion depth
                                    DispatchQueue.main.async {
                                        self.submitForm()
                                    }
                                case .failure(let error):
                                    self.isLoading = false
                                    self.isUpdatingProfile = false
                                    self.alertMessage = "Authentication expired. Please try again. (\(error.localizedDescription))"
                                    self.showAlert = true
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.isUpdatingProfile = false
                            self.alertMessage = "Failed to refresh authentication. Please sign in again."
                            self.showAlert = true
                        }
                    }
                }
            } else {
                self.isLoading = false
                self.isUpdatingProfile = false
                self.alertMessage = "Not authenticated. Please sign in again."
                self.showAlert = true
            }
            return
        }
        
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
