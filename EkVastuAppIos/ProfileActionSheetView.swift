import SwiftUI

struct ProfileActionSheetView: View {
    @Binding var isShowing: Bool
    @State private var showingSafari = false
    @State private var safariURL: URL?
    @State private var showEditProfile = false
    @State private var dragOffset = CGSize.zero
    @State private var animateContent = false
    
    var onLogout: () -> Void
    
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var appVersion: String = ""
    
    var body: some View {
        ZStack {
            // Enhanced background with blur effect
            Color.black.opacity(0.5)
                .background(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                }
            
            // Action sheet content
            VStack(spacing: 0) {
                // Enhanced handle
                Capsule()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Beautiful user profile section
                        VStack(spacing: 16) {
                            // Profile avatar placeholder with gradient
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF9500"), Color(hex: "#DD8E2E")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Text(String(userName.prefix(2)).uppercased())
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateContent ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                            
                            // User details card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Name")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)
                                        
                                        Text(userName)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                    .background(Color.secondary.opacity(0.3))
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                            .tracking(0.5)
                                        
                                        Text(userEmail)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .scaleEffect(animateContent ? 1 : 0.9)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                        }
                        .padding(.horizontal, 20)
                        
                        // Action buttons section
                        VStack(spacing: 12) {
                            // Edit Profile button - primary action
                            ActionButton(
                                icon: "person.circle.fill",
                                title: "Edit Profile",
                                subtitle: "Update your personal information",
                                isPrimary: true,
                                delay: 0.3
                            ) {
                                showEditProfile = true
                            }
                            
                            // Secondary action buttons
                            ActionButton(
                                icon: "rectangle.portrait.and.arrow.right.fill",
                                title: "Logout",
                                subtitle: "Sign out from your account",
                                isDestructive: true,
                                delay: 0.35
                            ) {
                                onLogout()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isShowing = false
                                }
                            }
                            
                            // Legal section
                            VStack(spacing: 8) {
                                SectionHeader(title: "Legal", delay: 0.4)
                                
                                LinkButton(
                                    icon: "doc.text.fill",
                                    title: "Terms & Conditions",
                                    delay: 0.45,
                                    url: "https://invinciblepassiontalkshow.com/terms-conditions"
                                )
                                
                                LinkButton(
                                    icon: "shield.fill",
                                    title: "Privacy Policy",
                                    delay: 0.5,
                                    url: "https://invinciblepassiontalkshow.com/privacy-policy-disclaimers"
                                )
                                
                                LinkButton(
                                    icon: "link.circle.fill",
                                    title: "Affiliate Disclaimers",
                                    delay: 0.55,
                                    url: "https://invinciblepassiontalkshow.com/affiliate-disclaimer"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // App version with nice styling
                        VStack(spacing: 8) {
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                                .padding(.horizontal, 20)
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                                
                                Text("Version \(appVersion)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .scaleEffect(animateContent ? 1 : 0.9)
                            .opacity(animateContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
                        }
                        
                        // Bottom padding for safe area
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemGroupedBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.85)
            .offset(y: dragOffset.height > 0 ? dragOffset.height : 0)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            self.dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.dragOffset = .zero
                            }
                        }
                    }
            )
            .position(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height - (UIScreen.main.bounds.height * 0.425)
            )
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            loadUserInfo()
            loadAppVersion()
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            UserDetailsForm(forceRefresh: true)
        }
    }
    
    private func loadUserInfo() {
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
    
    private func openURL(_ urlString: String) {
        safariURL = URL(string: urlString)
        showingSafari = true
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isPrimary: Bool
    let isDestructive: Bool
    let delay: Double
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animate = false
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isPrimary: Bool = false,
        isDestructive: Bool = false,
        delay: Double = 0,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.delay = delay
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconForegroundColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(titleColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .scaleEffect(animate ? 1 : 0.9)
            .opacity(animate ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var backgroundColor: Color {
        if isPrimary {
            return Color(hex: "#DD8E2E").opacity(0.1)
        } else if isDestructive {
            return Color.red.opacity(0.05)
        } else {
            return Color(UIColor.secondarySystemGroupedBackground)
        }
    }
    
    private var iconBackgroundColor: Color {
        if isPrimary {
            return Color(hex: "#DD8E2E")
        } else if isDestructive {
            return Color.red.opacity(0.1)
        } else {
            return Color(hex: "#DD8E2E").opacity(0.1)
        }
    }
    
    private var iconForegroundColor: Color {
        if isPrimary {
            return .white
        } else if isDestructive {
            return .red
        } else {
            return Color(hex: "#DD8E2E")
        }
    }
    
    private var titleColor: Color {
        isDestructive ? .red : .primary
    }
    
    private var shadowColor: Color {
        if isPrimary {
            return Color(hex: "#DD8E2E").opacity(0.2)
        } else {
            return Color.black.opacity(0.05)
        }
    }
}

// MARK: - Link Button Component
struct LinkButton: View {
    let icon: String
    let title: String
    let delay: Double
    let url: String
    
    @State private var animate = false
    @State private var isPressed = false
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#DD8E2E"))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemGroupedBackground))
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .scaleEffect(animate ? 1 : 0.95)
            .opacity(animate ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Section Header Component
struct SectionHeader: View {
    let title: String
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .scaleEffect(animate ? 1 : 0.9)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animate = true
            }
        }
    }
}


// MARK: - Rounded Corner Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

 
