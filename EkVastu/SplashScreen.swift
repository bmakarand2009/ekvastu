import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale: CGFloat = 0.8
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        if isActive {
            OnboardingView()
                .environment(\.managedObjectContext, viewContext)
        } else {
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

// Helper extension for hex color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
