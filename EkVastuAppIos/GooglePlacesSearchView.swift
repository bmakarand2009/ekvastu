import SwiftUI
import GooglePlaces
import CoreLocation

// Address search view for the sheet using GooglePlaces
struct AddressSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var searchResults: [PlacePrediction] = []
    @State private var isSearching = false
    let placesClient = GMSPlacesClient.shared()
    var onAddressSelected: (String, CLLocationCoordinate2D?) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for address", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onChange(of: searchText) { newValue in
                        if !newValue.isEmpty {
                            fetchPredictions(for: newValue)
                        } else {
                            searchResults = []
                        }
                    }
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else {
                    List(searchResults) { prediction in
                        Button(action: {
                            selectPlace(prediction)
                        }) {
                            VStack(alignment: .leading) {
                                Text(prediction.primaryText)
                                    .font(.headline)
                                Text(prediction.secondaryText)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Address")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func fetchPredictions(for query: String) {
        isSearching = true
        
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        
        placesClient.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { predictions, error in
            isSearching = false
            
            if let error = error {
                print("Error fetching predictions: \(error.localizedDescription)")
                return
            }
            
            if let predictions = predictions {
                self.searchResults = predictions.map { prediction in
                    return PlacePrediction(
                        id: prediction.placeID,
                        primaryText: prediction.attributedPrimaryText.string,
                        secondaryText: prediction.attributedSecondaryText?.string ?? "",
                        fullText: prediction.attributedFullText.string
                    )
                }
            }
        }
    }
    
    private func selectPlace(_ prediction: PlacePrediction) {
        let fields: GMSPlaceField = [.name, .formattedAddress, .coordinate]
        
        placesClient.fetchPlace(fromPlaceID: prediction.id, placeFields: fields, sessionToken: nil) { place, error in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                onAddressSelected(prediction.fullText, nil)
                presentationMode.wrappedValue.dismiss()
                return
            }
            
            if let place = place {
                onAddressSelected(place.formattedAddress ?? prediction.fullText, place.coordinate)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Model for place predictions
struct PlacePrediction: Identifiable {
    let id: String
    let primaryText: String
    let secondaryText: String
    let fullText: String
}
