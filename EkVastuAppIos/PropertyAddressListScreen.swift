import SwiftUI

struct PropertyAddressListScreen: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var addresses: [PropertyAddress] = []
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToAddAddress = false
    @State private var navigateToAnalyzeScreen = false
    @State private var selectedAddress: PropertyAddress?
    @State private var isRefreshing = false
    @State private var lastClickedAddress: PropertyAddress?
    @State private var lastClickTime: Date?
    @State private var navigateToEditAddress = false
    @State private var addressToEdit: PropertyAddress?
    @State private var navigateToUserDetailsForm = false
    
    // Property service for API calls
    private let propertyService = PropertyService.shared
    
    // Property type categories
    private let categories = ["Home", "Work", "Office", "Other"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            // Main content
            VStack(alignment: .center, spacing: 0) {
                // Header with back button and logo
                HStack {
                    // Back button always navigates to UserDetailsForm
                    Button(action: {
                        navigateToUserDetailsForm = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#4A2511"))
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Image("headerimage")
                        .frame(width: 78)
                    
                    Spacer()
                    
                    // Empty view for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                        .padding(.trailing, 20)
                }
                .padding(.top, 50)
                .padding(.bottom, 10)
                
               Text("Select property's address")
                   .font(.system(size: 22, weight: .bold))
                   .padding(.top, 20)
                   .padding(.bottom, 20)
                
                // Content area
                VStack(alignment: .leading, spacing: 10) {
                    // Loading indicator
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading properties...")
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    } else if addresses.isEmpty {
                        // No properties found message
                        VStack(spacing: 15) {
                            Image(systemName: "house.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No Properties Found")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text("You haven't added any properties yet. You can add up to 4 properties (one for each type: Residential, Work, Commercial, Other). Tap 'Add new Address' to get started.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Add new address button for empty state
                            Button(action: {
                                navigateToAddAddress = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16))
                                    Text("Add new Address")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#4A2511"))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 20)
                            
                            Button("Refresh") {
                                loadAddresses()
                            }
                            .foregroundColor(Color(hex: "#4A2511"))
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Group addresses by property type
                        ForEach(categories, id: \.self) { category in
                            // Only show the first address for each type
                            let filteredAddresses = addresses.filter { $0.propertyType.rawValue.lowercased() == category.lowercased() }
                            let addressToShow = filteredAddresses.first.map { [$0] } ?? []
                            
                            if !addressToShow.isEmpty {
                                // Category header
                                Text(category)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                // Only show one address per category
                                ForEach(addressToShow) { address in
                                    Button(action: {
                                        // Check for double-click first (for editing)
                                        handleAddressDoubleClick(address)
                                        
                                        // If not a double-click, set as selected and navigate
                                        selectedAddress = address
                                        
                                        // Add a small delay to allow double-click detection
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            // Only navigate if we haven't started editing (double-click)
                                            if !navigateToEditAddress {
                                                navigateToAnalyzeScreen = true
                                            }
                                        }
                                    }) {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white)
                                                .frame(height: 60)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(selectedAddress?.id == address.id ? Color(hex: "#4A2511") : Color.clear, lineWidth: 2)
                                                )
                                            
                                            HStack {
                                                Text(address.completeAddress)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.black.opacity(0.7))
                                                    .lineLimit(2)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(Color(hex: "#4A2511"))
                                                    .font(.system(size: 14))
                                            }
                                            .padding(.horizontal, 15)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Add new address button or limit message
                        if shouldShowAddButton() {
                            Button(action: {
                                navigateToAddAddress = true
                            }) {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 16))
                                Text("Add new Address")
                                    .font(.headline)
                            }
                            .foregroundColor(Color(hex: "#4A2511"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#D2B48C").opacity(0.7))
                            .cornerRadius(10)
                        }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 20)
                        } else {
                            // Show limit reached message when all 4 types are covered
                            let existingTypes = Set(addresses.map { $0.propertyType.rawValue })
                            if existingTypes.count >= 4 {
                                VStack(spacing: 10) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.green)
                                        Text("All Property Types Added")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                    }
                                    
                                    Text("You have added all 4 property types (Residential, Work, Commercial, Other). You can edit existing properties by double-tapping them.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.top, 20)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Instruction text at the bottom
                Text("Tap on an address to analyze your property")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationBarHidden(true)  // Hide navigation bar
        .navigationBarBackButtonHidden(true)  // Hide back button
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)  // iOS 16+
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Message"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Always load addresses when screen appears
            print("PropertyAddressListScreen appeared, loading addresses")
            // Reset addresses array to trigger loading state
            self.addresses = []
            // Load addresses with a slight delay to ensure view is fully presented
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                loadAddresses()
            }
        }
        .onDisappear {
            // Reset selection when leaving the screen
            selectedAddress = nil
        }
        .fullScreenCover(isPresented: $navigateToAddAddress, onDismiss: {
            // Refresh addresses when returning from PropertyAddressScreen
            loadAddresses()
        }) {
            PropertyAddressScreen()
                .navigationBarHidden(true)  // Also hide in child views
        }
        .fullScreenCover(isPresented: $navigateToAnalyzeScreen) {
            AnalyzeYourProperty(
                selectedPropertyType: selectedAddress?.propertyType.rawValue.lowercased() ?? "residential",
                propertyId: selectedAddress?.id ?? ""
            )
                .navigationBarHidden(true)  // Also hide in child views
        }
        .fullScreenCover(isPresented: $navigateToEditAddress, onDismiss: {
            // Refresh addresses when returning from editing
            loadAddresses()
        }) {
            PropertyAddressScreen(addressToEdit: addressToEdit)
                .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $navigateToUserDetailsForm) {
            UserDetailsForm(forceRefresh: true)
                .navigationBarHidden(true)
        }
    }
    
    private func loadAddresses() {
        isLoading = true
        print("Loading addresses from backend API...")
        
        // Fetch properties from backend API
        propertyService.getAllProperties { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let properties = response.data {
                        print("Loaded \(properties.count) properties from backend")
                        
                        // Convert PropertyData to PropertyAddress
                        let convertedAddresses = properties.compactMap { property in
                            self.convertPropertyDataToAddress(property)
                        }
                        
                        for address in convertedAddresses {
                            print("Address: \(address.location), Type: \(address.propertyType.rawValue), ID: \(address.id ?? "unknown")")
                        }
                        
                        // Keep only the first address of each type for display
                        var uniqueAddresses: [PropertyAddress] = []
                        var seenTypes: Set<String> = []
                        
                        for address in convertedAddresses {
                            let type = address.propertyType.rawValue
                            if !seenTypes.contains(type) {
                                uniqueAddresses.append(address)
                                seenTypes.insert(type)
                            }
                        }
                        
                        self.addresses = uniqueAddresses
                    } else {
                        print("Failed to load properties: \(response.message ?? "Unknown error")")
                        self.alertMessage = response.message ?? "Failed to load properties"
                        self.showAlert = true
                        self.addresses = []
                    }
                    
                case .failure(let error):
                    print("Error loading properties: \(error.localizedDescription)")
                    self.alertMessage = "Error loading properties: \(error.localizedDescription)"
                    self.showAlert = true
                    self.addresses = []
                }
            }
        }
    }
    
    // Helper function to convert PropertyData to PropertyAddress
    private func convertPropertyDataToAddress(_ property: PropertyData) -> PropertyAddress? {
        // Map property type to PropertyAddress.PropertyType
        let propertyType: PropertyAddress.PropertyType
        switch property.type.lowercased() {
        case "home", "residential":
            propertyType = .home
        case "work":
            propertyType = .work
        case "office", "commercial":
            propertyType = .office
        default:
            propertyType = .other
        }
        
        // Create complete address from property fields
        let completeAddress = "\(property.street), \(property.city), \(property.state) \(property.zip), \(property.country)"
        
        return PropertyAddress(
            location: property.name,
            completeAddress: completeAddress,
            pincode: property.zip,
            propertyType: propertyType,
            latitude: nil, // Will be geocoded if needed
            longitude: nil, // Will be geocoded if needed
            id: property.id
        )
    }
    
    // Check if we should show the Add New Address button
    private func shouldShowAddButton() -> Bool {
        // Show button only if we don't have all 4 property types
        let existingTypes = Set(addresses.map { $0.propertyType.rawValue })
        let shouldShow = existingTypes.count < 4
        print("🔘 Add button visibility: \(shouldShow) (existing types: \(existingTypes.count)/4)")
        return shouldShow
    }
    
    // Handle double-click detection for editing addresses
    private func handleAddressDoubleClick(_ address: PropertyAddress) {
        let now = Date()
        
        // Check if this is a double click (same address clicked twice within 0.5 seconds)
        if let lastClickTime = lastClickTime,
           let lastClickedAddress = lastClickedAddress,
           lastClickedAddress.id == address.id,
           now.timeIntervalSince(lastClickTime) < 0.5 {
            
            // Double click detected - prepare for editing
            print("Double click detected on address: \(address.location)")
            addressToEdit = address
            navigateToEditAddress = true
            
            // Reset tracking variables
            self.lastClickTime = nil
            self.lastClickedAddress = nil
        } else {
            // First click - update tracking variables
            lastClickTime = now
            lastClickedAddress = address
        }
    }
}

struct AddressCard: View {
    let address: PropertyAddress
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(address.propertyType.rawValue)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(address.completeAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color(hex: "#4A2511") : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal)
        }
    }
}

struct PropertyAddressListScreen_Previews: PreviewProvider {
    static var previews: some View {
        PropertyAddressListScreen()
            .environmentObject(AuthenticationManager.shared)
    }
}
