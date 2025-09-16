import SwiftUI
import Firebase
import FirebaseAuth

struct SplashScreen: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale: CGFloat = 0.8
    @State private var isVerifyingAuth = true
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if isActive {
                if authManager.isAuthenticated {
                    if AuthenticationManager.isCheckingUserStatus {
                        // Show loading screen while checking user status
                        LoadingView(message: "Loading your profile...")
                    } else {
                        // Show appropriate view based on user status
                        switch authManager.getPostLoginViewType() {
                        case .userDetails:
                            UserDetailsForm()
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(authManager)
                                .buttonStyle(.plain)
                        case .propertyAddress:
                            PropertyAddressListScreen()
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(authManager)
                                .buttonStyle(.plain)
                        case .mainContent:
                            ContentView()
                                .environment(\.managedObjectContext, viewContext)
                                .environmentObject(authManager)
                                .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Show onboarding for non-authenticated users
                    OnboardingView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(authManager)
                }
            } else {
                // Splash screen
                ZStack {
                    Color(hex: "#202020").ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        Image("splash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .opacity(opacity)
                            .scaleEffect(scale)
                        Spacer()
                    }
                }
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.opacity = 1.0
                        self.scale = 1.0
                    }
                    
                    // Verify Firebase auth state before proceeding
                    verifyAuthenticationState()
                }
            }
        }
    }
    
    private func verifyAuthenticationState() {
        // Re-check Firebase auth state when app launches
        if let user = Auth.auth().currentUser {
            print("Verifying Firebase user on app launch: \(user.uid)")
            
            // Force reload to verify account still exists
            user.reload { error in
                if let error = error as NSError? {
                    if error.code == AuthErrorCode.userNotFound.rawValue || 
                       error.code == AuthErrorCode.userDisabled.rawValue {
                        print("Firebase account no longer exists - clearing data")
                        self.authManager.signOut()
                    }
                }
                
                // Check user status after verification
                if self.authManager.isAuthenticated {
                    self.authManager.checkUserStatus {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.isActive = true
                                self.isVerifyingAuth = false
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                            self.isVerifyingAuth = false
                        }
                    }
                }
            }
        } else {
            // No Firebase user, proceed normally
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    self.isActive = true
                    self.isVerifyingAuth = false
                }
            }
        }
    }
}

// Loading view for status checking
struct LoadingView: View {
    var message: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F9CBA6"), Color(hex: "#FFF4EB")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                
                Text(message)
                    .font(.headline)
                    .padding(.top, 20)
            }
        }
    }
}
