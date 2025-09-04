import SwiftUI

struct HomeAnalyzeView: View {
    @State private var selectedRoomType: String = "Select room type"
    @State private var isRoomTypeSelected: Bool = false
    @State private var isDropdownOpen = false
    
    // Room types available for selection
    private let roomTypes = ["Living room", "Bedroom", "Office Room", "Kitchen", "Hall", "Balcony", "Study Room", "Bath Room"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                // Logo at the top
                Image("headerimage")
                    .frame(width: 78)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text("Analyze your space")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal)
                
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
                    }
                    .buttonStyle(PlainButtonStyle())
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
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Dropdown menu
                            if isDropdownOpen {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(roomTypes, id: \.self) { roomType in
                                        Button(action: {
                                            selectedRoomType = roomType
                                            isDropdownOpen = false
                                            isRoomTypeSelected = true
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
                                .background(isRoomTypeSelected ? Color(hex: "#4A2511") : Color.gray)
                                .cornerRadius(8)
                        }
                        .disabled(!isRoomTypeSelected)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
}
