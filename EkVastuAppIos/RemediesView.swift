import SwiftUI

struct RemediesView: View {
    var body: some View {
        VStack {
            // Logo at the top
            Image("headerimage")
                .frame(width: 78)
                .padding(.top, 50)
                .padding(.bottom, 10)
            
            Text("Vastu Remedies")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RemedyCard(
                        title: "Entrance Remedies",
                        description: "Optimize your home's energy flow with these entrance remedies.",
                        imageName: "house.fill"
                    )
                    
                    RemedyCard(
                        title: "Living Room Remedies",
                        description: "Create harmony and balance in your living spaces.",
                        imageName: "sofa.fill"
                    )
                    
                    RemedyCard(
                        title: "Bedroom Remedies",
                        description: "Improve sleep quality and relationship harmony.",
                        imageName: "bed.double.fill"
                    )
                    
                    RemedyCard(
                        title: "Kitchen Remedies",
                        description: "Enhance prosperity and health through kitchen adjustments.",
                        imageName: "cooktop.fill"
                    )
                    
                    RemedyCard(
                        title: "Office Remedies",
                        description: "Boost productivity and career success.",
                        imageName: "desktopcomputer"
                    )
                }
                .padding()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct RemedyCard: View {
    let title: String
    let description: String
    let imageName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: imageName)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#4A2511"))
                    .frame(width: 40, height: 40)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            Button(action: {
                // Action for viewing remedy details
            }) {
                Text("View Details")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#4A2511"))
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct RemediesView_Previews: PreviewProvider {
    static var previews: some View {
        RemediesView()
    }
}
