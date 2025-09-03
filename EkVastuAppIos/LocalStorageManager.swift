import Foundation

class LocalStorageManager {
    static let shared = LocalStorageManager()
    
    private let propertyAddressesKey = "savedPropertyAddresses"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // Save property addresses to UserDefaults
    func savePropertyAddresses(_ addresses: [PropertyAddress]) {
        do {
            let data = try JSONEncoder().encode(addresses)
            userDefaults.set(data, forKey: propertyAddressesKey)
            print("Successfully saved \(addresses.count) addresses to local storage")
        } catch {
            print("Error saving addresses to local storage: \(error.localizedDescription)")
        }
    }
    
    // Load property addresses from UserDefaults
    func loadPropertyAddresses() -> [PropertyAddress] {
        guard let data = userDefaults.data(forKey: propertyAddressesKey) else {
            print("No addresses found in local storage")
            return []
        }
        
        do {
            let addresses = try JSONDecoder().decode([PropertyAddress].self, from: data)
            print("Successfully loaded \(addresses.count) addresses from local storage")
            return addresses
        } catch {
            print("Error loading addresses from local storage: \(error.localizedDescription)")
            return []
        }
    }
    
    // Save a single property address
    func savePropertyAddress(_ address: PropertyAddress, completion: @escaping (Bool, Error?) -> Void) {
        var addresses = loadPropertyAddresses()
        
        // If the address has an ID, update the existing one
        if let id = address.id, let index = addresses.firstIndex(where: { $0.id == id }) {
            addresses[index] = address
        } else {
            // Otherwise add as new with a generated ID
            var newAddress = address
            newAddress.id = UUID().uuidString
            addresses.append(newAddress)
        }
        
        // Save the updated list
        do {
            let data = try JSONEncoder().encode(addresses)
            userDefaults.set(data, forKey: propertyAddressesKey)
            print("Successfully saved/updated address in local storage")
            completion(true, nil)
        } catch {
            print("Error saving address to local storage: \(error.localizedDescription)")
            completion(false, error)
        }
    }
    
    // Delete a property address
    func deletePropertyAddress(withId id: String) -> Bool {
        var addresses = loadPropertyAddresses()
        
        guard let index = addresses.firstIndex(where: { $0.id == id }) else {
            print("Address with ID \(id) not found in local storage")
            return false
        }
        
        addresses.remove(at: index)
        
        do {
            let data = try JSONEncoder().encode(addresses)
            userDefaults.set(data, forKey: propertyAddressesKey)
            print("Successfully deleted address from local storage")
            return true
        } catch {
            print("Error deleting address from local storage: \(error.localizedDescription)")
            return false
        }
    }
    
    // Clear all property addresses
    func clearAllPropertyAddresses() {
        userDefaults.removeObject(forKey: propertyAddressesKey)
        print("Cleared all addresses from local storage")
    }
}
