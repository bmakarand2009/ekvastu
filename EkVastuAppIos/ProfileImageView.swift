import SwiftUI

struct ProfileImageView: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 1
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var showingActionSheet = false
    @State private var navigateToOnboarding = false
    
    var body: some View {
        ZStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: lineWidth))
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: size, height: size)
            } else {
                // Fallback image when no profile picture is available
                Image(systemName: "person.crop.circle")
                    .font(.system(size: size))
                    .foregroundColor(.black)
            }
        }
        .onTapGesture {
            showingActionSheet = true
        }
        .onAppear {
            loadProfileImage()
        }
        .fullScreenCover(isPresented: $navigateToOnboarding) {
            // Navigate to onboarding screen after logout
            OnboardingView()
        }
        .fullScreenCover(isPresented: $showingActionSheet) {
            ZStack {
                Color.clear.background(.ultraThinMaterial)
                ProfileActionSheetView(isShowing: $showingActionSheet, onLogout: handleLogout)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func loadProfileImage() {
        // Get the profile picture URL from UserDefaults
        if let urlString = UserDefaults.standard.string(forKey: "user_picture"),
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            
            isLoading = true
            
            // Download the image asynchronously
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let data = data, let image = UIImage(data: data) {
                        self.profileImage = image
                    }
                }
            }.resume()
        }
    }
    
    private func handleLogout() {
        // Use LogoutManager to handle the logout process
        LogoutManager.shared.logout {
            // After logout is complete, navigate to onboarding
            DispatchQueue.main.async {
                self.navigateToOnboarding = true
            }
        }
    }
}

#Preview {
    ProfileImageView()
}
