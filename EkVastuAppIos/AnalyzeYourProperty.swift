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
            // Set the default tab to Home
            selectedTab = 0
            
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}


struct AnalyzeYourProperty_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeYourProperty()
    }
}
