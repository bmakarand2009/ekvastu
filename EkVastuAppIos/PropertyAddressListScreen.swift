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
    
    // Property type categories
    private let categories = ["Home", "Work", "Office", "Other"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FFCC99"), Color(hex: "#FFCC99")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            // Main content
            VStack(alignment: .center, spacing: 0) {
                // Logo at the top
                Image("headerimage")
                    .frame(width: 78)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                
                // Title
                Text("Select property's address")
                    .font(.title3)
                    .padding(.bottom, 20)
                
                // Content area
                VStack(alignment: .leading, spacing: 10) {
                    // Loading indicator
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 20)
                            Spacer()
                        }
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
                                        handleAddressClick(address)
                                    }) {
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.white)
                                                .frame(height: 60)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(selectedAddress?.id == address.id ? Color(hex: "#4A2511") : Color.clear, lineWidth: 2)
                                                )
                                            
                                            Text(address.completeAddress)
                                                .font(.system(size: 15))
                                                .foregroundColor(.black.opacity(0.7))
                                                .padding(.horizontal, 15)
                                                .lineLimit(2)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Add new address button - only show if we don't have all 4 types of addresses
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Next button at the bottom
                Button(action: {
                    if selectedAddress == nil {
                        alertMessage = "Please select an address to continue"
                        showAlert = true
                    } else {
                        navigateToAnalyzeScreen = true
                    }
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#4A2511"))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
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
            AnalyzeYourProperty()
                .navigationBarHidden(true)  // Also hide in child views
        }
        .fullScreenCover(isPresented: $navigateToEditAddress, onDismiss: {
            // Refresh addresses when returning from editing
            loadAddresses()
        }) {
            PropertyAddressScreen(addressToEdit: addressToEdit)
                .navigationBarHidden(true)
        }
    }
    
    private func loadAddresses() {
        isLoading = true
        print("Loading addresses from local storage...")
        
        // Use local storage instead of Firestore
        PropertyAddress.fetchFromLocalStorage { addresses, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error loading addresses: \(error.localizedDescription)")
                    self.alertMessage = "Error loading addresses: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                if let addresses = addresses {
                    print("Loaded \(addresses.count) addresses from local storage")
                    for address in addresses {
                        print("Address: \(address.location), Type: \(address.propertyType.rawValue), ID: \(address.id ?? "unknown")")
                    }
                    
                    // Keep only the first address of each type
                    var uniqueAddresses: [PropertyAddress] = []
                    var seenTypes: Set<String> = []
                    
                    for address in addresses {
                        let type = address.propertyType.rawValue
                        if !seenTypes.contains(type) {
                            uniqueAddresses.append(address)
                            seenTypes.insert(type)
                        }
                    }
                    
                    self.addresses = uniqueAddresses
                } else {
                    print("No addresses returned from local storage")
                    self.addresses = []
                }
            }
        }
    }
    
    // Check if we should show the Add New Address button
    private func shouldShowAddButton() -> Bool {
        // Count how many different property types we have
        let existingTypes = Set(addresses.map { $0.propertyType.rawValue })
        
        // If we have all 4 types, don't show the button
        return existingTypes.count < 4
    }
    
    // Handle address click with double-click detection
    private func handleAddressClick(_ address: PropertyAddress) {
        // Set as selected address (for single click)
        selectedAddress = address
        
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
