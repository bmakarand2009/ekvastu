//
//  EkVastuApp.swift
//  EkVastu
//
//  Created by Venkata Avula  on 8/29/25.
//

import SwiftUI
import CoreData

@main
struct EkVastuApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
