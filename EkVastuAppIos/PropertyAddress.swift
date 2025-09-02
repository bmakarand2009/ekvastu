import Foundation
import FirebaseAuth
import CoreLocation
import FirebaseFirestore

struct PropertyAddress: Codable {
    var location: String
    var completeAddress: String
    var pincode: String
    var propertyType: PropertyType
    var latitude: Double?
    var longitude: Double?
    
    // Firebase document ID for this property
    var documentId: String?
    
    enum PropertyType: String, Codable, CaseIterable {
        case home = "Home"
        case work = "Work"
        case office = "Office"
        case other = "Other"
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "location": location,
            "completeAddress": completeAddress,
            "pincode": pincode,
            "propertyType": propertyType.rawValue
        ]
        
        if let latitude = latitude {
            dict["latitude"] = latitude
        }
        
        if let longitude = longitude {
            dict["longitude"] = longitude
        }
        
        return dict
    }
    
    // Create from Firestore document
    static func fromDictionary(_ data: [String: Any], documentId: String? = nil) -> PropertyAddress? {
        guard 
            let location = data["location"] as? String,
            let completeAddress = data["completeAddress"] as? String,
            let pincode = data["pincode"] as? String,
            let propertyTypeString = data["propertyType"] as? String,
            let propertyType = PropertyType(rawValue: propertyTypeString)
        else {
            return nil
        }
        
        var propertyAddress = PropertyAddress(
            location: location,
            completeAddress: completeAddress,
            pincode: pincode,
            propertyType: propertyType
        )
        
        propertyAddress.latitude = data["latitude"] as? Double
        propertyAddress.longitude = data["longitude"] as? Double
        propertyAddress.documentId = documentId
        
        return propertyAddress
    }
    
    // Save to Firestore
    func saveToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "PropertyAddress", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let db = Firestore.firestore()
        let propertyRef = db.collection("users").document(userId).collection("properties").document()
        
        propertyRef.setData(self.toDictionary()) { error in
            if let error = error {
                print("Error saving property address: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("Property address saved successfully")
                completion(true, nil)
            }
        }
    }
    
    // Fetch from Firestore
    static func fetchFromFirestore(completion: @escaping ([PropertyAddress]?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "PropertyAddress", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let db = Firestore.firestore()
        let propertiesRef = db.collection("users").document(userId).collection("properties")
        
        propertiesRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching property addresses: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let snapshot = snapshot else {
                completion([], nil)
                return
            }
            
            let properties = snapshot.documents.compactMap { document -> PropertyAddress? in
                guard let data = document.data() as [String: Any]? else { return nil }
                return PropertyAddress.fromDictionary(data, documentId: document.documentID)
            }
            
            completion(properties, nil)
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
