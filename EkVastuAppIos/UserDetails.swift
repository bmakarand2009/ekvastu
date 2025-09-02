import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserDetails: Codable {
    var name: String
    var dateOfBirth: Date
    var timeOfBirth: Date
    var placeOfBirth: String
    var hasCompletedDetails: Bool = true
    
    // Firebase document ID for this user
    var documentId: String?
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "timeOfBirth": Timestamp(date: timeOfBirth),
            "placeOfBirth": placeOfBirth,
            "hasCompletedDetails": hasCompletedDetails
        ]
    }
    
    // Create from Firestore document
    static func fromDictionary(_ data: [String: Any], documentId: String? = nil) -> UserDetails? {
        guard 
            let name = data["name"] as? String,
            let dateOfBirthTimestamp = data["dateOfBirth"] as? Timestamp,
            let timeOfBirthTimestamp = data["timeOfBirth"] as? Timestamp,
            let placeOfBirth = data["placeOfBirth"] as? String,
            let hasCompletedDetails = data["hasCompletedDetails"] as? Bool
        else {
            return nil
        }
        
        var userDetails = UserDetails(
            name: name,
            dateOfBirth: dateOfBirthTimestamp.dateValue(),
            timeOfBirth: timeOfBirthTimestamp.dateValue(),
            placeOfBirth: placeOfBirth,
            hasCompletedDetails: hasCompletedDetails
        )
        
        userDetails.documentId = documentId
        return userDetails
    }
    
    // Save to Firestore
    func saveToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "UserDetails", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.setData(self.toDictionary()) { error in
            if let error = error {
                print("Error saving user details: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("User details saved successfully")
                completion(true, nil)
            }
        }
    }
    
    // Fetch from Firestore
    static func fetchFromFirestore(completion: @escaping (UserDetails?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserDetails", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil, NSError(domain: "UserDetails", code: 2, userInfo: [NSLocalizedDescriptionKey: "User details not found"]))
                return
            }
            
            if let userDetails = UserDetails.fromDictionary(data, documentId: document.documentID) {
                completion(userDetails, nil)
            } else {
                completion(nil, NSError(domain: "UserDetails", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user details"]))
            }
        }
    }
}
