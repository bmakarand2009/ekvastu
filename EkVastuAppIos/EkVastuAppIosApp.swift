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
import UIKit

@main
struct EkVastuAppIosApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Firebase is already configured in AppDelegate
        // Do not initialize Firebase here to avoid duplicate initialization
        
        // Force Light Mode - Using the newer API for iOS 15+
        if #available(iOS 15.0, *) {
            // This will be handled in the onAppear block instead
        } else {
            // Legacy approach for older iOS versions
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        
        // Set the appearance for UIKit elements
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    // Handle the URL that the app was launched with
                    GIDSignIn.sharedInstance.handle(url)
                }
                .preferredColorScheme(.light) // Force light mode at the SwiftUI level
                .onAppear {
                    // Force light mode at the UIKit level for iOS 15+
                    if #available(iOS 15.0, *) {
                        let scenes = UIApplication.shared.connectedScenes
                        guard let windowScene = scenes.first as? UIWindowScene else { return }
                        windowScene.keyWindow?.overrideUserInterfaceStyle = .light
                    }
                }
        }
    }
}
