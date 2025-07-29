// Month Budget/Application/Month_BudgetApp.swift
import SwiftUI

@main
struct Month_BudgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
