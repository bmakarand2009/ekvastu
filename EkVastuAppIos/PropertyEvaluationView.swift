import SwiftUI

struct PropertyEvaluationView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image("ekshakti")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.customBrown)
                }
            }
            .padding()
            .background(Color.white)
            
            // Tab selection
            HStack(spacing: 0) {
                TabButton(title: "Camera", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Compass", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .padding(.horizontal)
            
            // Tab content
            TabView(selection: $selectedTab) {
                CameraView()
                    .tag(0)
                
                CompassView()
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedTab)
        }
        .navigationBarHidden(true)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.customBrown : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.customBrown : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct PropertyEvaluationView_Previews: PreviewProvider {
    static var previews: some View {
        PropertyEvaluationView()
            .environmentObject(AuthenticationManager.shared)
    }
}
