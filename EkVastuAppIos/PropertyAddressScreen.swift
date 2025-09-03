import SwiftUI
import Firebase
import GoogleMaps
import GooglePlaces
import CoreLocation

struct PropertyAddressScreen: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var location = ""
    @State private var completeAddress = ""
    @State private var pincode = ""
    @State private var propertyType: PropertyAddress.PropertyType = .home
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629) // Default to India
    @State private var mapMarker: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToAddressList = false
    @State private var showChangeAddressSheet = false
    @State private var showPropertyEvaluation = false
    @State private var suggestedAddresses: [GMSAutocompletePrediction] = []
    @State private var showSuggestions = false
    @State private var placesClient = GMSPlacesClient.shared()
    
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
                    // Title
                    Text("Enter property's address")
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
                        
                        HStack {
                            TextField("Sun City Apartments, Opposite Dmart...", text: $location)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                            
                            Button("Change address") {
                                showChangeAddressSheet = true
                            }
                            .foregroundColor(.green)
                            .font(.caption)
                        }
                        
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
                        
                        // Map marker indicator
                        if let _ = mapMarker {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Text("Selected Location")
                                            .font(.caption)
                                            .foregroundColor(.black)
                                            .padding(8)
                                            .background(Color.white)
                                            .cornerRadius(4)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: -20, y: -20)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Next button
                    Button(action: savePropertyAddress) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: "#8B4513"))
                                .frame(height: 50)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Next")
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
        filter.country = "IN" // Restrict to India
        
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
        
        isLoading = true
        
        var propertyAddress = PropertyAddress(
            location: location,
            completeAddress: completeAddress,
            pincode: pincode,
            propertyType: propertyType
        )
        
        if let coordinate = mapMarker {
            propertyAddress.latitude = coordinate.latitude
            propertyAddress.longitude = coordinate.longitude
        }
        
        // Save to Firestore
        propertyAddress.saveToFirestore { success, error in
            isLoading = false
            
            if success {
                // Navigate to address list screen
                navigateToAddressList = true
            } else {
                alertMessage = error?.localizedDescription ?? "Failed to save property address"
                showAlert = true
            }
        }
    }
}

struct PropertyAddressScreen_Previews: PreviewProvider {
    static var previews: some View {
        PropertyAddressScreen()
            .environmentObject(AuthenticationManager.shared)
    }
}
