import Foundation
import CoreLocation

struct PropertyAddress: Codable, Identifiable {
    var location: String
    var completeAddress: String
    var pincode: String
    var propertyType: PropertyType
    var latitude: Double?
    var longitude: Double?
    
    // Unique identifier for this property
    var id: String?
    
    // For backward compatibility
    var documentId: String? {
        get { return id }
        set { id = newValue }
    }
    
    enum PropertyType: String, Codable, CaseIterable {
        case home = "Home"
        case work = "Work"
        case office = "Office"
        case other = "Other"
    }
    
    // Save to local storage
    func saveToLocalStorage(completion: @escaping (Bool, Error?) -> Void) {
        LocalStorageManager.shared.savePropertyAddress(self, completion: completion)
    }
    
    // Fetch from local storage
    static func fetchFromLocalStorage(completion: @escaping ([PropertyAddress]?, Error?) -> Void) {
        let addresses = LocalStorageManager.shared.loadPropertyAddresses()
        completion(addresses, nil)
    }
    
    // For backward compatibility - redirects to local storage
    func saveToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        saveToLocalStorage(completion: completion)
    }
    
    // For backward compatibility - redirects to local storage
    static func fetchFromFirestore(completion: @escaping ([PropertyAddress]?, Error?) -> Void) {
        fetchFromLocalStorage(completion: completion)
    }
    
    // Convert PropertyType to API-compatible string
    var propertyTypeForAPI: String {
        switch self.propertyType {
        case .home: return "residential"
        case .work: return "work"
        case .office: return "office"
        case .other: return "other"
        }
    }
    
    // Geocode address to get coordinates
    func geocodeAddress(completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        let addressString = "\(completeAddress), \(pincode)"
        
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil, NSError(domain: "PropertyAddress", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not geocode address"]))
                return
            }
            
            completion(location.coordinate, nil)
        }
    }
}
