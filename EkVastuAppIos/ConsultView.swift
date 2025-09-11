import SwiftUI
import SafariServices

struct ConsultView: View {
    // State variables for accordion sections
    @State private var expandedSection: Int? = nil
    @State private var showingSafari = false
    
    // URL for booking with Jaya
    private let bookingUrl = URL(string: "https://bookme.name/JayaKaramchandani/discovery-call-home-vastu-visit-online-session")!
    
    var body: some View {
        ZStack {
            // Background color
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Top navigation bar
                    topNavigationBar
                    
                    // Top section with Jaya image
                    consultHeaderCard
                    
                    // Let's Begin Your Consultation text
                    Text("Let's Begin Your Consultation")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // Coffee with Jaya button - left aligned
                    HStack {
                        Button(action: {
                            showingSafari = true
                        }) {
                            Text("Coffee with Jaya")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color(hex: "#DD8E2E"))
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .sheet(isPresented: $showingSafari) {
                        SafariView(url: bookingUrl)
                    }
                    
                    
                }
                .padding(.vertical, 15)
            }
        }
        
        .onAppear {
            // Start with the first section expanded
            expandedSection = 1
        }
    }
    
    // MARK: - Header Card
    private var consultHeaderCard: some View {
        ZStack {
            // White background with pattern
            HStack {
                // Left side content
                VStack(alignment: .leading, spacing: 5) {
                    Text("Initial Consultation with Jaya Karamchandani")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 10)
                    
                    Text("Unlock Your Home's Potential with a Vastu Consultation")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 15)
                .padding(.vertical, 15)
                
                Spacer()
                
                // Right side image
                Image("jaya")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
            }
            .background(
                ZStack(alignment: .trailing) {
                    Color.white
                    
                    // Vastu pattern overlay
                    Image("vastu_pattern")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                        .opacity(0.8)
                }
            )
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 15) {
            // EK Logo
            Image("headerimage")
                .frame(width: 40, height: 40)
            
            Spacer()
            
            // Bell icon
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Profile image
            Image("jaya") // Using jaya as a placeholder for profile
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
            
            // Menu button
            Button(action: {}) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    
}
