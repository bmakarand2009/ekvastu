import SwiftUI

struct ProfileImageView: View {
    var size: CGFloat = 24
    var lineWidth: CGFloat = 1
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: lineWidth))
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: size, height: size)
            } else {
                // Fallback image when no profile picture is available
                Image(systemName: "person.crop.circle")
                    .font(.system(size: size))
                    .foregroundColor(.black)
            }
        }
        .onAppear {
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        // Get the profile picture URL from UserDefaults
        if let urlString = UserDefaults.standard.string(forKey: "user_picture"),
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            
            isLoading = true
            
            // Download the image asynchronously
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let data = data, let image = UIImage(data: data) {
                        self.profileImage = image
                    }
                }
            }.resume()
        }
    }
}

#Preview {
    ProfileImageView()
}
