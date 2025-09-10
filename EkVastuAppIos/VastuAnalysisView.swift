import SwiftUI

struct VastuAnalysisView: View {
    let room: VastuGalleryView.RoomWithPhotos
    
    @Environment(\.presentationMode) var presentationMode
    @State private var loadedImages: [UIImage?] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Back button and title
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Text("Analysis of Your Room")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Analysis card
                    analysisCard
                    
                    // Vastu Gallery card
                    vastuGalleryCard
                    
                    Spacer(minLength: 100) // Space for bottom navigation
                }
                .padding(.vertical, 12)
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .onAppear { loadImages() }
    }
    
    // Analysis card with Connect with Jaya button
    private var analysisCard: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Analysis of your room requires a few more details")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("For detailed analysis and personalized recommendations, consult with Jaya.")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            
            HStack {
                Button(action: {
                    // Navigate to Consult tab
                    NotificationCenter.default.post(name: NSNotification.Name("SwitchToConsultTab"), object: nil)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Connect with Jaya")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .frame(height: 36)
                        .background(Color(hex: "#DD8E2E"))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
        .overlay(
            Image("vastu_pattern")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .opacity(0.7)
                .padding(.trailing, -20)
                .padding(.bottom, 0),
            alignment: .bottomTrailing
        )
    }
    
    // Vastu Gallery card with View Library button
    private var vastuGalleryCard: some View {
        VStack(spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .center) {
                        Text("Vastu Gallery")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            // Navigate to Vastu Gallery View
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("View Property")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .frame(height: 36)
                                .background(Color(hex: "#DD8E2E"))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text("View Property Images")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    private func loadImages() {
        isLoading = true
        loadedImages = Array(repeating: nil, count: room.photos.count)
        guard !room.photos.isEmpty else { isLoading = false; return }
        let group = DispatchGroup()
        for (index, p) in room.photos.enumerated() {
            group.enter()
            Task {
                if let url = URL(string: p.uri) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        let image = UIImage(data: data)
                        DispatchQueue.main.async { self.loadedImages[index] = image; group.leave() }
                    } catch {
                        DispatchQueue.main.async { group.leave() }
                    }
                } else {
                    DispatchQueue.main.async { group.leave() }
                }
            }
        }
        group.notify(queue: .main) { isLoading = false }
    }
}
