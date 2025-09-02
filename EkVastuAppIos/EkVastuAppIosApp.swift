//
//  EkVastuApp.swift
//  EkVastu
//
//  Created by Venkata Avula  on 8/29/25.
//

import SwiftUI
import CoreData
import Firebase
import GoogleSignIn

@main
struct EkVastuAppIosApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    // Handle the URL that the app was launched with
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
