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
    @State private var navigateToHome = false
    @State private var showChangeAddressSheet = false
    @State private var showPropertyEvaluation = false
    
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
                        // App header with logo
                        HStack {
                            Image("ekshakti")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                            
                            Text("EkVastu")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Welcome message
                        Text("Welcome, \(authManager.getUserDisplayName())")
                            .font(.headline)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Form fields
                        VStack(alignment: .leading, spacing: 15) {
                            // Location field with change address option
                            HStack {
                                Text("Location")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Change address") {
                                    showChangeAddressSheet = true
                                }
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            }
                            
                            TextField("Enter location", text: $location)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("Complete Address")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            TextField("Enter complete address", text: $completeAddress)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            Text("Pincode")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            TextField("Enter pincode", text: $pincode)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .keyboardType(.numberPad)
                            
                            Text("Property Type")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            // Property type selection buttons
                            HStack(spacing: 10) {
                                ForEach(PropertyAddress.PropertyType.allCases, id: \.self) { type in
                                    Button(action: {
                                        propertyType = type
                                    }) {
                                        Text(type.rawValue)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 15)
                                            .background(propertyType == type ? Color(hex: "#8B4513") : Color.white.opacity(0.9))
                                            .foregroundColor(propertyType == type ? .white : .black)
                                            .cornerRadius(8)
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                        
                        // Map view
                        VStack(alignment: .leading) {
                            Text("Location on Map")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ZStack {
                                if let mapMarker = mapMarker {
                                    GoogleMapsView(coordinate: $mapCenter, markers: [
                                        createMarker(position: mapMarker, title: location, snippet: completeAddress)
                                    ])
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                } else {
                                    GoogleMapsView(coordinate: $mapCenter, markers: [])
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                }
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            
                            Button("Update Map") {
                                updateMapLocation()
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        }
                        
                        // Property Evaluation Button
                        Button(action: {
                            showPropertyEvaluation = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Evaluate Property")
                                Image(systemName: "location.north.fill")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#A0522D"))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .disabled(location.isEmpty || completeAddress.isEmpty || pincode.isEmpty || isLoading)
                        
                        NavigationLink(
                            destination: ContentView(),
                            isActive: $navigateToHome,
                            label: { EmptyView() }
                        )
                        
                        NavigationLink(
                            destination: PropertyEvaluationView(),
                            isActive: $showPropertyEvaluation,
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
            isLoading = false
            
            if let error = error {
                alertMessage = "Geocoding error: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                alertMessage = "Could not find location on map"
                showAlert = true
                return
            }
            
            mapCenter = location.coordinate
            mapMarker = location.coordinate
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
                // Navigate to home screen
                navigateToHome = true
            } else {
                alertMessage = error?.localizedDescription ?? "Failed to save property address"
                showAlert = true
            }
        }
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


struct PropertyAddressScreen_Previews: PreviewProvider {
    static var previews: some View {
        PropertyAddressScreen()
            .environmentObject(AuthenticationManager.shared)
    }
}
