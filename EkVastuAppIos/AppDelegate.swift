import UIKit
import Sentry

import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import FirebaseAppCheck
import GoogleSignIn
import AuthenticationServices
import GoogleMaps
import GooglePlaces
import CoreData
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // TEMPORARILY DISABLED SENTRY
        // SentrySDK.start { options in
        //     options.dsn = "https://d6fd49f8ec29112c7e77b15312ba5025@o726296.ingest.us.sentry.io/4510015802245120"
        //     options.debug = true // Enabled debug when first installing is always helpful

        //     // Adds IP for users.
        //     // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
        //     options.sendDefaultPii = true

        //     // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        //     // We recommend adjusting this value in production.
        //     options.tracesSampleRate = 1.0

        //     // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
        //     options.configureProfiling = {
        //         $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
        //         $0.lifecycle = .trace
        //     }

        //     // Uncomment the following lines to add more data to your events
        //     // options.attachScreenshot = true // This adds a screenshot to the error events
        //     // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
        //     // Enable experimental logging features
        //     options.experimental.enableLogs = true
        // }
        // // Remove the next line after confirming that your Sentry integration is working.
        // SentrySDK.capture(message: "This app uses Sentry! :)")

        // Configure Firebase App Check before Firebase initialization
        #if DEBUG
        // Use debug provider for development
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("🔧 Firebase App Check: Using DEBUG provider")
        #else
        // Use App Attest provider for production
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("🔧 Firebase App Check: Using App Attest provider")
#endif
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Force App Check token generation to get debug token - only in debug builds
        #if DEBUG
        // Use a non-blocking approach with a timeout to prevent build issues
        DispatchQueue.global(qos: .background).async {
            let semaphore = DispatchSemaphore(value: 0)
            var tokenGenerated = false
            
            AppCheck.appCheck().token(forcingRefresh: true) { token, error in
                if let error = error {
                    print("❌ App Check Debug Token Error: \(error.localizedDescription)")
                } else if let token = token {
                    print("✅ App Check Debug Token Generated: \(token.token)")
                    print("📋 COPY THIS DEBUG TOKEN TO FIREBASE CONSOLE:")
                    print("🔑 \(token.token)")
                    tokenGenerated = true
                }
                semaphore.signal()
            }
            
            // Wait with timeout to prevent blocking indefinitely
            _ = semaphore.wait(timeout: .now() + 5.0)
            if !tokenGenerated {
                print("⚠️ App Check token generation timed out or failed")
            }
        }
        #endif
        
        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 and above
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            // For iOS 9 and below
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Enable debug logging
        print("=== App Launch: Starting Google Sign-In Debug ===")
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "Not found")")
        
        // Initialize Google Maps SDK
        // TODO: Replace with your actual Google Maps API key
        GMSServices.provideAPIKey("AIzaSyCiIbvc_BUCEiItFKPN9CUev3vmcCgmEZQ")
        GMSPlacesClient.provideAPIKey("AIzaSyCiIbvc_BUCEiItFKPN9CUev3vmcCgmEZQ")
        
        // Get client ID from Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            print("ERROR: GIDClientID not found in Info.plist")
            return false
        }
        
        print("GIDClientID from Info.plist: \(clientID)")
        
        // Clear keychain to resolve persistent issues
        print("Clearing keychain data for Google Sign-In")
        KeychainHelper.clearKeychain()
        
        #if targetEnvironment(simulator)
        // Additional simulator-specific keychain reset
        print("Running on simulator - performing additional keychain reset")
        SimulatorUtility.resetKeychain()
        
        // Set up keychain access group override for simulator
        print("Setting up keychain access group override for simulator")
        KeychainAccessGroup.setupAccessGroup()
        #endif
        
        // Configure Google Sign-In with proper initialization
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        print("Google Sign-In configured with client ID")
        
        // Try to restore previous sign-in
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Failed to restore previous sign-in: \(error.localizedDescription)")
            } else if let user = user {
                print("Successfully restored sign-in for user: \(user.profile?.email ?? "Unknown")")
                
                // Print the ID token
                if let idToken = user.idToken?.tokenString {
                    print("ID Token: \(idToken)")
                    
                    // Authenticate with Firebase using Google Sign-In credentials
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                                  accessToken: user.accessToken.tokenString)
                    
                    // Sign in to Firebase with the Google credential
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            print("Firebase sign-in error: \(error.localizedDescription)")
                            return
                        }
                        
                        // Notify the AuthenticationManager about the restored Google sign-in
                        NotificationCenter.default.post(
                            name: Notification.Name("GoogleSignInRestored"),
                            object: nil,
                            userInfo: ["user": user]
                        )
                        
                        print("Successfully signed in to Firebase with Google")
                    }
                } else {
                    print("ID Token not available")
                }
                print("Access Token: \(user.accessToken.tokenString)")
            } else {
                print("No previous sign-in found")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Firebase Messaging Delegate Methods
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    // MARK: - UNUserNotificationCenter Delegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received notification while app in foreground: \(userInfo)")
        
        // Show the notification in foreground
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Handling notification response: \(userInfo)")
        
        completionHandler()
    }
}
