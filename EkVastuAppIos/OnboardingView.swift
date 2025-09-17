import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isOnboardingComplete = false
    @State private var showSignIn = false
    @State private var showErrorMessage = false
    @State private var errorMessage: String = ""
    
    // Initialize notification observer
    init() {
        setupNotificationObserver()
    }
    
    // Set up notification observer to handle back navigation and error messages
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("ReturnToOnboarding"), object: nil, queue: .main) { _ in
            showSignIn = false
        }
        
        // Add observer for Google login error
        NotificationCenter.default.addObserver(forName: Notification.Name("GoogleLoginNoValidContactError"), object: nil, queue: .main) { notification in
            if let message = notification.userInfo?["errorMessage"] as? String {
                self.errorMessage = message
                self.showErrorMessage = true
                self.showSignIn = false
            }
        }
    }
    
    var body: some View {
        if showSignIn {
            NavigationView {
                SignInPage()
            }
        } else if isOnboardingComplete {
            ContentView()
                .onAppear {
                    // Clear any pending alerts from previous sessions
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("ClearAllAlerts"), object: nil)
                    }
                }
        } else {
            ZStack {
                // Background color
                Color.white.ignoresSafeArea()
                
                VStack {
                    // Error message banner
                    if showErrorMessage {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .padding(.leading, 15)
                                
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 5)
                                
                                Spacer()
                                
                                Button(action: {
                                    showErrorMessage = false
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 15)
                                }
                            }
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                    TabView(selection: $currentPage) {
                        // First slide
                        OnboardingSlide(
                            image: "slide1",
                            title: "Book a consultation with Jaya anytime.",
                            buttonText: "Next",
                            pageIndex: 0,
                            currentPage: $currentPage,
                            isLastPage: false,
                            onComplete: { isOnboardingComplete = true }
                        )
                        .tag(0)
                        
                        // Second slide
                        OnboardingSlide(
                            image: "slide2",
                            title: "Get personalized remedies and easy fixes.",
                            buttonText: "Next",
                            pageIndex: 1,
                            currentPage: $currentPage,
                            isLastPage: false,
                            onComplete: { isOnboardingComplete = true }
                        )
                        .tag(1)
                        
                        // Third slide
                        OnboardingSlide(
                            image: "slide3",
                            title: "Check your room's Vastu health instantly",
                            buttonText: "Login",
                            pageIndex: 2,
                            currentPage: $currentPage,
                            isLastPage: true,
                            onComplete: { showSignIn = true }
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                }
            }
        }
    }
}

struct OnboardingSlide: View {
    let image: String
    let title: String
    let buttonText: String
    let pageIndex: Int
    @Binding var currentPage: Int
    let isLastPage: Bool
    let onComplete: () -> Void
    @State private var navigateToCreateAccount = false
    
    var body: some View {
        VStack {
            // Image at the top - full width
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width)
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .clipped()
            
            Spacer()
            
            // Title text
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color(hex: "#4A2511") : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, 40)
            
            // Button
            Button(action: {
                if isLastPage {
                    // If it's the login button (last slide), show create account page
                    if buttonText == "Login" {
                        onComplete()
                    } else {
                        currentPage += 1
                    }
                } else {
                    currentPage += 1
                }
            }) {
                Text(buttonText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#4A2511"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
