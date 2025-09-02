import CoreData
import CoreTransferable
import StoreKit
import AppIntents
import os.log

struct PersistenceController {
    static let shared = PersistenceController()
    private static let logger = Logger(subsystem: "org.ekshakti.EkVastu", category: "PersistenceController")

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "EkVastu")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error instead of crashing in production
                Self.logger.error("Core Data store failed to load: \(error.localizedDescription)")
                #if DEBUG
                print("Core Data store failed to load: \(error), \(error.userInfo)")
                #endif
            } else {
                Self.logger.info("Core Data store loaded successfully")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        // No sample data needed for preview
        return result
    }()
}
