//
//  Month_BudgetApp.swift
//  Month Budget
//
//  Created by Kyrylo Tokariev on 11.03.2025.
//

import SwiftUI

@main
struct Month_BudgetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
