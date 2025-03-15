import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Month_Budget") // Must match exactly
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Помилка завантаження Core Data: \(error), \(error.userInfo)")
            }
        }
    }
}
