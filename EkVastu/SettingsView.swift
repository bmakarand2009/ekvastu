import SwiftUI

struct SettingsView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#ECD2BE"), Color(hex: "#FEA45A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            }
        }
    }
}

#Preview {
    SettingsView()
}
