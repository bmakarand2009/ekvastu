import SwiftUI
import GoogleMaps
import GooglePlaces
import CoreLocation

struct PropertyAddressScreen: View {
    // Optional property to edit - if nil, we're adding a new address
    var addressToEdit: PropertyAddress?
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var location = ""
    @State private var completeAddress = ""
    @State private var pincode = ""
    @State private var propertyType: PropertyAddress.PropertyType = .home
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795) // Default to center of world (USA center)
    @State private var mapMarker: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToAddressList = false
    @State private var showChangeAddressSheet = false
    @State private var showPropertyEvaluation = false
    @State private var isEditMode = false
    @State private var suggestedAddresses: [GMSAutocompletePrediction] = []
    @State private var showSuggestions = false
    @State private var placesClient = GMSPlacesClient.shared()
    @Environment(\.presentationMode) var presentationMode
    
    // Property service for API calls
    private let propertyService = PropertyService.shared
    
    init(addressToEdit: PropertyAddress? = nil) {
        self.addressToEdit = addressToEdit
        
        // Initialize state variables if we're editing an existing address
        if let address = addressToEdit {
            _location = State(initialValue: address.location)
            _completeAddress = State(initialValue: address.completeAddress)
            _pincode = State(initialValue: address.pincode)
            _propertyType = State(initialValue: address.propertyType)
            _isEditMode = State(initialValue: true)
            
            if let latitude = address.latitude, let longitude = address.longitude {
                _mapCenter = State(initialValue: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                _mapMarker = State(initialValue: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
    }
    
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
                    
                    // Logo and header with back button
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(hex: "#4A2511"))
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                        
                        Image("headerimage")
                            .frame(width: 78)
                            .padding(.top, 30)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(isEditMode ? "Edit property's address" : "Enter property's address")
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 15) {
                        // Your Location field
                        Text("Your Location")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        
                        Button(action: {
                            showChangeAddressSheet = true
                        }) {
                            TextField("Sun City Apartments, Opposite Dmart...", text: $location)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .disabled(true)
                        }
                        .buttonStyle(.plain)
                        
                        // Complete Address
                        Text("Complete Address")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.top, 10)
                        
                        TextField("708 A1 Sun City Apartments, Opposite Dmart, Chinchwad Pune", text: $completeAddress)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                        
                        // Pincode
                        Text("Pincode")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.top, 10)
                        
                        TextField("411002", text: $pincode)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .keyboardType(.numberPad)
                        
                        // Property Type
                        Text("Select Property type")
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .padding(.top, 10)
                        
                        // Property type selection buttons
                        HStack(spacing: 10) {
                            Button(action: {
                                propertyType = .home
                            }) {
                                Text("Home")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .background(propertyType == .home ? Color.green : Color.white)
                                    .foregroundColor(propertyType == .home ? .white : .black)
                                    .cornerRadius(20)
                            }.buttonStyle(.plain)
                            
                            Button(action: {
                                propertyType = .work
                            }) {
                                Text("Work")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .background(propertyType == .work ? Color.green : Color.white)
                                    .foregroundColor(propertyType == .work ? .white : .black)
                                    .cornerRadius(20)
                            }.buttonStyle(.plain)
                            
                            Button(action: {
                                propertyType = .office
                            }) {
                                Text("Office")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .background(propertyType == .office ? Color.green : Color.white)
                                    .foregroundColor(propertyType == .office ? .white : .black)
                                    .cornerRadius(20)
                            }.buttonStyle(.plain)
                            
                            Button(action: {
                                propertyType = .other
                            }) {
                                Text("Other")
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 15)
                                    .background(propertyType == .other ? Color.green : Color.white)
                                    .foregroundColor(propertyType == .other ? .white : .black)
                                    .cornerRadius(20)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Map view
                    ZStack {
                        if let mapMarker = mapMarker {
                            GoogleMapsView(coordinate: $mapCenter, markers: [
                                createMarker(position: mapMarker, title: location, snippet: completeAddress)
                            ])
                            .frame(height: 250)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        } else {
                            GoogleMapsView(coordinate: $mapCenter, markers: [])
                            .frame(height: 250)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .frame(width: 50, height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                        }
                        
                        // Map marker with no text indicator
                    }
                    
                    // Save/Update button
                    Button(action: savePropertyAddress) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#8B4513"))
                                .frame(height: 50)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isEditMode ? "Update" : "Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }.buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .disabled(location.isEmpty || completeAddress.isEmpty || pincode.isEmpty || isLoading)
                }
                .padding(.bottom, 30)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Message"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showChangeAddressSheet) {
            AddressSearchView(onAddressSelected: { address, coordinate in
                self.location = address.components(separatedBy: ",").first ?? address
                self.completeAddress = address
                
                if let coordinate = coordinate {
                    self.mapCenter = coordinate
                    self.mapMarker = coordinate
                    
                    // Get pincode from reverse geocoding
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { placemarks, error in
                        if let placemark = placemarks?.first {
                            self.pincode = placemark.postalCode ?? ""
                        }
                    }
                }
            })
        }
        .fullScreenCover(isPresented: $navigateToAddressList) {
            PropertyAddressListScreen()
                .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showPropertyEvaluation) {
            PropertyEvaluationView()
        }
    }
    
    // Helper function to create Google Maps markers
    private func createMarker(position: CLLocationCoordinate2D, title: String, snippet: String) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = position
        marker.title = title
        marker.snippet = snippet
        marker.appearAnimation = .pop
        return marker
    }
    
    private func fetchSuggestedAddresses(for query: String) {
        let token = GMSAutocompleteSessionToken.init()
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        // Remove country restriction to enable worldwide address search
        
        placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: token) { predictions, error in
            if let error = error {
                print("Error fetching autocomplete predictions: \(error.localizedDescription)")
                return
            }
            
            if let predictions = predictions {
                DispatchQueue.main.async {
                    self.suggestedAddresses = predictions
                }
            }
        }
    }
    
    private func selectAddress(_ prediction: GMSAutocompletePrediction) {
        let token = GMSAutocompleteSessionToken.init()
        
        placesClient.fetchPlace(fromPlaceID: prediction.placeID, placeFields: .all, sessionToken: token) { place, error in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                DispatchQueue.main.async {
                    self.location = prediction.attributedPrimaryText.string
                    self.completeAddress = place.formattedAddress ?? prediction.attributedFullText.string
                    
                    self.mapCenter = place.coordinate
                    self.mapMarker = place.coordinate
                    self.updatePincodeFromCoordinate(place.coordinate)
                }
            }
        }
    }
    
    private func updatePincodeFromCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.pincode = placemark.postalCode ?? ""
                }
            }
        }
    }
    
    private func updateMapLocation() {
        guard !completeAddress.isEmpty else {
            alertMessage = "Please enter an address first"
            showAlert = true
            return
        }
        
        isLoading = true
        
        let geocoder = CLGeocoder()
        let addressString = "\(completeAddress), \(pincode)"
        
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.alertMessage = "Geocoding error: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self.alertMessage = "Could not find location on map"
                    self.showAlert = true
                    return
                }
                
                self.mapCenter = location.coordinate
                self.mapMarker = location.coordinate
            }
        }
    }
    
    private func savePropertyAddress() {
        guard !location.isEmpty, !completeAddress.isEmpty, !pincode.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        // Show loading indicator
        isLoading = true
        
        if isEditMode, let existingAddress = addressToEdit, let propertyId = existingAddress.id {
            // Update existing property via API
            updatePropertyViaAPI(propertyId: propertyId)
        } else {
            // Create new property via API
            createPropertyViaAPI()
        }
    }
    
    private func createPropertyViaAPI() {
        print("🆕 Creating new property via API...")
        
        // First, check if a property of this type already exists
        checkForExistingPropertyType { typeExists in
            if typeExists {
                // Show error message for duplicate type
                let typeName = self.getPropertyTypeName(self.propertyType)
                self.alertMessage = "\(typeName) property already exists. You can only have one property per type."
                self.showAlert = true
                self.isLoading = false
                return
            }
            
            // Proceed with property creation if type doesn't exist
            self.proceedWithPropertyCreation()
        }
    }
    
    private func checkForExistingPropertyType(completion: @escaping (Bool) -> Void) {
        print("🔍 Checking for existing properties of type: \(propertyType.rawValue)")
        
        propertyService.getAllProperties { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let properties = response.data {
                        // Map property type to API format for comparison
                        let apiPropertyType = self.mapPropertyTypeToAPI(self.propertyType)
                        
                        // Check if any existing property has the same type
                        let typeExists = properties.contains { property in
                            property.type.lowercased() == apiPropertyType.lowercased()
                        }
                        
                        print("🔍 Type '\(apiPropertyType)' exists: \(typeExists)")
                        completion(typeExists)
                    } else {
                        // If we can't fetch properties, allow creation (fail-safe)
                        print("⚠️ Could not fetch properties, allowing creation")
                        completion(false)
                    }
                    
                case .failure(let error):
                    print("❌ Error checking existing properties: \(error.localizedDescription)")
                    // If we can't fetch properties, allow creation (fail-safe)
                    completion(false)
                }
            }
        }
    }
    
    private func proceedWithPropertyCreation() {
        print("✅ Proceeding with property creation...")
        
        // Parse complete address to extract components
        let addressComponents = parseCompleteAddress(completeAddress)
        
        // Map property type to API format
        let apiPropertyType = mapPropertyTypeToAPI(propertyType)
        
        propertyService.createProperty(
            name: location,
            type: apiPropertyType,
            street: addressComponents.street,
            city: addressComponents.city,
            state: addressComponents.state,
            zip: pincode,
            country: addressComponents.country
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        print("✅ Property created successfully via API")
                        // Navigate back to the list screen
                        self.navigateToAddressList = true
                    } else {
                        self.alertMessage = response.message ?? "Failed to create property"
                        self.showAlert = true
                    }
                    
                case .failure(let error):
                    print("❌ Failed to create property: \(error.localizedDescription)")
                    self.alertMessage = "Failed to create property: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    // Helper function to get user-friendly property type name
    private func getPropertyTypeName(_ type: PropertyAddress.PropertyType) -> String {
        switch type {
        case .home:
            return "Residential"
        case .work:
            return "Work"
        case .office:
            return "Commercial"
        case .other:
            return "Other"
        }
    }
    
    private func updatePropertyViaAPI(propertyId: String) {
        print("✏️ Updating property via API...")
        
        // Check if property type has changed and if the new type already exists
        if let existingAddress = addressToEdit {
            let currentApiType = mapPropertyTypeToAPI(existingAddress.propertyType)
            let newApiType = mapPropertyTypeToAPI(propertyType)
            
            // If type has changed, check if new type already exists
            if currentApiType.lowercased() != newApiType.lowercased() {
                checkForExistingPropertyType { typeExists in
                    if typeExists {
                        // Show error message for duplicate type
                        let typeName = self.getPropertyTypeName(self.propertyType)
                        self.alertMessage = "\(typeName) property already exists. You can only have one property per type."
                        self.showAlert = true
                        self.isLoading = false
                        return
                    }
                    
                    // Proceed with update if new type doesn't exist
                    self.proceedWithPropertyUpdate(propertyId: propertyId)
                }
                return
            }
        }
        
        // If type hasn't changed or no existing address, proceed with update
        proceedWithPropertyUpdate(propertyId: propertyId)
    }
    
    private func proceedWithPropertyUpdate(propertyId: String) {
        print("✅ Proceeding with property update...")
        
        // Parse complete address to extract components
        let addressComponents = parseCompleteAddress(completeAddress)
        
        // Map property type to API format
        let apiPropertyType = mapPropertyTypeToAPI(propertyType)
        
        propertyService.updateProperty(
            id: propertyId,
            name: location,
            type: apiPropertyType,
            street: addressComponents.street,
            city: addressComponents.city,
            state: addressComponents.state,
            zip: pincode,
            country: addressComponents.country
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        print("✅ Property updated successfully via API")
                        // Navigate back to the list screen
                        self.navigateToAddressList = true
                    } else {
                        self.alertMessage = response.message ?? "Failed to update property"
                        self.showAlert = true
                    }
                    
                case .failure(let error):
                    print("❌ Failed to update property: \(error.localizedDescription)")
                    self.alertMessage = "Failed to update property: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    // Helper function to parse complete address into components
    private func parseCompleteAddress(_ address: String) -> (street: String, city: String, state: String, country: String) {
        let components = address.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Default values
        var street = ""
        var city = ""
        var state = ""
        var country = "India" // Default country
        
        if components.count >= 1 {
            street = components[0]
        }
        if components.count >= 2 {
            city = components[1]
        }
        if components.count >= 3 {
            state = components[2]
        }
        if components.count >= 4 {
            country = components[3]
        }
        
        // If we don't have enough components, try to extract from the full address
        if city.isEmpty && !street.isEmpty {
            city = "Unknown City"
        }
        if state.isEmpty && !city.isEmpty {
            state = "Unknown State"
        }
        
        return (street: street, city: city, state: state, country: country)
    }
    
    // Helper function to map PropertyType to API format
    private func mapPropertyTypeToAPI(_ type: PropertyAddress.PropertyType) -> String {
        switch type {
        case .home:
            return "residential"
        case .work:
            return "work"
        case .office:
            return "commercial"
        case .other:
            return "other"
        }
    }
}
