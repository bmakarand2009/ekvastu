import SwiftUI

struct ProfilePopupView: View {
    @Binding var isShowing: Bool
    var onLogout: () -> Void
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var appVersion: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info section
            VStack(alignment: .leading, spacing: 8) {
                Text(userName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(userEmail)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Logout button
            Button(action: {
                onLogout()
                isShowing = false
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#DD8E2E"))
                    
                    Text("Logout")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            // App version
            HStack {
                Text("App Version")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(appVersion)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .frame(width: 220)
        .onAppear {
            loadUserInfo()
            loadAppVersion()
        }
    }
    
    private func loadUserInfo() {
        // Get user name and email from UserDefaults
        userName = UserDefaults.standard.string(forKey: "user_name") ?? "User"
        userEmail = UserDefaults.standard.string(forKey: "user_email") ?? "No email"
    }
    
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = "\(version) (\(build))"
        } else {
            appVersion = "Unknown"
        }
    }
}

#Preview {
    ProfilePopupView(isShowing: .constant(true), onLogout: {})
}
