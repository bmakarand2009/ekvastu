import Foundation

struct UserDetails: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var dateOfBirth: Date
    var timeOfBirth: Date
    var placeOfBirth: String
    var hasCompletedDetails: Bool = true
    
    // For backward compatibility with Firebase code
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "dateOfBirth": dateOfBirth,
            "timeOfBirth": timeOfBirth,
            "placeOfBirth": placeOfBirth,
            "hasCompletedDetails": hasCompletedDetails
        ]
    }
    
    // Save to local storage
    func saveToLocalStorage(completion: @escaping (Bool, Error?) -> Void) {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: "userDetails")
            print("User details saved successfully to local storage")
            completion(true, nil)
        } catch {
            print("Error saving user details to local storage: \(error.localizedDescription)")
            completion(false, error)
        }
    }
    
    // Fetch from local storage
    static func fetchFromLocalStorage(completion: @escaping (UserDetails?, Error?) -> Void) {
        guard let data = UserDefaults.standard.data(forKey: "userDetails") else {
            completion(nil, NSError(domain: "UserDetails", code: 2, userInfo: [NSLocalizedDescriptionKey: "User details not found in local storage"]))
            return
        }
        
        do {
            let userDetails = try JSONDecoder().decode(UserDetails.self, from: data)
            completion(userDetails, nil)
        } catch {
            print("Error decoding user details from local storage: \(error.localizedDescription)")
            completion(nil, error)
        }
    }
    
    // For backward compatibility with Firebase code
    func saveToFirestore(completion: @escaping (Bool, Error?) -> Void) {
        // Redirect to local storage implementation
        saveToLocalStorage(completion: completion)
    }
    
    // For backward compatibility with Firebase code
    static func fetchFromFirestore(completion: @escaping (UserDetails?, Error?) -> Void) {
        // Redirect to local storage implementation
        fetchFromLocalStorage(completion: completion)
    }
}
