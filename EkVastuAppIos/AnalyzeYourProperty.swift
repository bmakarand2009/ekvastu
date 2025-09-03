import SwiftUI

struct AnalyzeYourProperty: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRoomType: String = "Select room type"
    @State private var isDropdownOpen = false
    
    // Room types available for selection
    private let roomTypes = ["Living room", "Bedroom", "Office Room", "Kitchen", "Hall", "Balcony", "Study Room", "Bath Room"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ScrollView {
                // Main content
                VStack(alignment: .center, spacing: 0) {
                    // Logo at the top
                    Image("headerimage")
                        .frame(width: 78)
                        .padding(.top, 50)
                        .padding(.bottom, 10)
                    
                }
                
                VStack(alignment: .leading, spacing: 0) {
                   
                    // Title
                    Text("Analyze your space")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        
                        .padding(.bottom,10)
                   
                }
                
                VStack(alignment: .center, spacing: 0) {
                   
                    // Property image
                    Image("property")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Description text
                    Text("Start your Vastu journey by scanning the entrance of your home to check its alignment, then select a room type to analyze and receive personalized insights.")
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    // Analyze Entrance button
                    Button(action: {
                        // Action for analyzing entrance
                    }) {
                        Text("Analyze Entrance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color(hex: "#4A2511"))
                            .cornerRadius(8)
                    }.buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Room selection dropdown and Start Analysis button
                    HStack(spacing: 10) {
                        // Custom dropdown button
                        ZStack {
                            Button(action: {
                                withAnimation {
                                    isDropdownOpen.toggle()
                                }
                            }) {
                                HStack {
                                    Text(selectedRoomType)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                        .rotationEffect(isDropdownOpen ? .degrees(180) : .degrees(0))
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            }.buttonStyle(.plain)
                            
                            // Dropdown menu
                            if isDropdownOpen {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(roomTypes, id: \.self) { roomType in
                                        Button(action: {
                                            selectedRoomType = roomType
                                            isDropdownOpen = false
                                        }) {
                                            Text(roomType)
                                                .foregroundColor(.black)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding()
                                                .background(Color.white)
                                        }
                                        Divider()
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .offset(y: 50)
                                .zIndex(1)
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.55)
                        
                        // Start Analysis button
                        Button(action: {
                            // Action for starting analysis
                        }) {
                            Text("Start Analysis")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(8)
                        }
                    }.buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.bottom, 50) // Add padding for the tab bar
            }
            
            // Tab bar at the bottom
            HStack(spacing: 0) {
                Spacer()
                
                // Home tab
                VStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                    Text("Home")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Remedies tab
                VStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                    Text("Remedies")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Consult tab
                VStack(spacing: 5) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 22))
                    Text("Consult")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}

// Using the Color extension from ColorExtension.swift

struct AnalyzeYourProperty_Previews: PreviewProvider {
    static var previews: some View {
        AnalyzeYourProperty()
    }
}
