import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale: CGFloat = 0.8
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
                            PropertyAddressScreen()
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
                    
                    // Check if user is already authenticated
                    if authManager.isAuthenticated {
                        // Check user status (completed details, property address, etc.)
                        authManager.checkUserStatus {
                            // Activate main view after checking status
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    } else {
                        // Show onboarding after splash
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
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
