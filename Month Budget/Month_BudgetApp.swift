import SwiftUI

@main
struct Month_BudgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
