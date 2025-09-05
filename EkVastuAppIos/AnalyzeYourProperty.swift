import SwiftUI

struct AnalyzeYourProperty: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeAnalyzeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CompassView()
                .tabItem {
                    Image(systemName: "safari")
                    Text("Compass")
                }
                .tag(1)
            
            RemediesView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Remedies")
                }
                .tag(2)
            
            ConsultView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Consult")
                }
                .tag(3)
        }
        .accentColor(Color(hex: "#4A2511"))
        .onAppear {
            selectedTab = 0
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        // Remove default selection background
        UITabBar.appearance().selectionIndicatorImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.white
        
        // Force clear selection indicator
        appearance.selectionIndicatorTintColor = UIColor.clear
        
        // Create a completely custom item appearance
        let itemAppearance = UITabBarItemAppearance()
        
        // Clear all possible background colors
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        itemAppearance.selected.iconColor = UIColor(Color(hex: "#4A2511"))
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(hex: "#4A2511"))]
        
        // Apply to all states and layouts
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Force override system behavior
        DispatchQueue.main.async {
            if let tabBar = UIApplication.shared.windows.first?.rootViewController?.view.subviews.first(where: { $0 is UITabBar }) as? UITabBar {
                tabBar.standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    tabBar.scrollEdgeAppearance = appearance
                }
            }
        }
    }
    
    private func configureTabBarItemAppearance(_ itemAppearance: UITabBarItemAppearance) {
        // Normal state
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]
        itemAppearance.normal.badgeBackgroundColor = UIColor.clear
        
        // Selected state - IMPORTANT: Remove background
        itemAppearance.selected.iconColor = UIColor(Color(hex: "#4A2511"))
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#4A2511"))
        ]
        itemAppearance.selected.badgeBackgroundColor = UIColor.clear
        
        // Focused state (for accessibility)
        itemAppearance.focused.iconColor = UIColor(Color(hex: "#4A2511"))
        itemAppearance.focused.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#4A2511"))
        ]
        itemAppearance.focused.badgeBackgroundColor = UIColor.clear
        
        // Disabled state
        itemAppearance.disabled.iconColor = UIColor.lightGray
        itemAppearance.disabled.titleTextAttributes = [
            .foregroundColor: UIColor.lightGray
        ]
        itemAppearance.disabled.badgeBackgroundColor = UIColor.clear
    }
}
