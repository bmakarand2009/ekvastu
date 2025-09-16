import SwiftUI
import GooglePlaces
import CoreLocation

struct AddressSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var predictions: [GMSAutocompletePrediction] = []
    @State private var isLoading = false
    
    var onAddressSelected: (String, CLLocationCoordinate2D?) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for address", text: $searchText)
                        .accentColor(.black) // Make cursor visible
                        .onChange(of: searchText) { oldValue, newValue in
                            if !newValue.isEmpty && newValue.count > 2 {
                                fetchPredictions(for: newValue)
                            } else {
                                predictions = []
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            predictions = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    // Results list
                    List(predictions, id: \.placeID) { prediction in
                        Button(action: {
                            selectAddress(prediction)
                        }) {
                            VStack(alignment: .leading) {
                                Text(prediction.attributedPrimaryText.string)
                                    .font(.headline)
                                Text(prediction.attributedSecondaryText?.string ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle("Search Address", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func fetchPredictions(for query: String) {
        isLoading = true
        
        let token = GMSAutocompleteSessionToken.init()
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        // Remove country restriction to enable worldwide address search
        
        GMSPlacesClient.shared().findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: token) { predictions, error in
            isLoading = false
            
            if let error = error {
                print("Error fetching predictions: \(error.localizedDescription)")
                return
            }
            
            if let predictions = predictions {
                self.predictions = predictions
            }
        }
    }
    
    private func selectAddress(_ prediction: GMSAutocompletePrediction) {
        let token = GMSAutocompleteSessionToken.init()
        
        // Use Places SDK v10 API to fetch place details with coordinates
        GMSPlacesClient.shared().fetchPlace(fromPlaceID: prediction.placeID, placeFields: .all, sessionToken: token) { place, error in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                onAddressSelected(prediction.attributedFullText.string, nil)
                presentationMode.wrappedValue.dismiss()
                return
            }
            
            if let place = place {
                let address = place.formattedAddress ?? prediction.attributedFullText.string
                onAddressSelected(address, place.coordinate)
                presentationMode.wrappedValue.dismiss()
            } else {
                onAddressSelected(prediction.attributedFullText.string, nil)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct AddressSearchView_Previews: PreviewProvider {
    static var previews: some View {
        AddressSearchView(onAddressSelected: { _, _ in })
    }
}
