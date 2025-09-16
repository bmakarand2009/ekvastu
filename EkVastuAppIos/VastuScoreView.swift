import SwiftUI
import SafariServices

struct VastuScoreView: View {
    let roomId: String
    let roomName: String
    let answers: [RoomAnswerItem]
    
    // Add a binding to control navigation when dismissing
    @Binding var shouldNavigateToHome: Bool

    @Environment(\.presentationMode) var presentationMode
    @State private var isSubmitting = true
    @State private var errorMessage: String? = nil
    @State private var score: RoomVastuScore? = nil
    @State private var navigateToGallery = false
    @State private var showSafari = false
    @State private var navigateToHomeAnalyze = false
    @State private var roomPropertyId: String = "" // Store the room's property ID

    private let service = VastuService.shared
    
    // Add an initializer with a default value for shouldNavigateToHome
    init(roomId: String, roomName: String, answers: [RoomAnswerItem], shouldNavigateToHome: Binding<Bool> = .constant(true)) {
        self.roomId = roomId
        self.roomName = roomName
        self.answers = answers
        self._shouldNavigateToHome = shouldNavigateToHome
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Title and description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Here's how your space aligns with Vastu principles and the top remedies you can apply today.")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 16) // Add top padding to increase gap from title
                        }
                        .padding(.top, 12) // Add additional spacing after the header
                        
                        // Score card
                        if let s = score {
                            VStack(alignment: .leading, spacing: 16) {
                                // Room name - use roomName from props if not in API response
                                Text(s.room_name ?? roomName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                // Score card
                                HStack(spacing: 16) {
                                    // Shield icon
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                    
                                    // Score text
                                    Text(getScoreRating(percentage: s.displayPercentage))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    // Score value
                                    Text("\(Int(s.displayPercentage))/100")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                            }
                        } else if let msg = errorMessage {
                            // Error message with better styling
                            VStack(alignment: .center, spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                    .padding(.bottom, 8)
                                
                                Text("Unable to load score")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text(msg)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Retry button
                                Button(action: {
                                    submitAndLoad() // Retry loading
                                }) {
                                    Text("Retry")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 30)
                                        .background(Color(hex: "#DD8E2E"))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 16)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        } else if isSubmitting {
                            ProgressView("Calculating Vastu Score...")
                                .padding()
                        }
                        
                        // Vastu Gallery card
                        vastuGalleryCard
                        
                        Spacer(minLength: 40)
                        
                        // Bottom buttons
                        HStack(spacing: 12) {
                            Button(action: { 
                                // Open in-app browser with Jaya's booking URL
                                showSafari = true
                            }) {
                                Text("Coffee With Jaya")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "#DD8E2E"))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                // Navigate to HomeAnalyzeView
                                navigateToHomeAnalyze = true
                            }) {
                                Text("Analyze Other Rooms")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#DD8E2E"))
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(hex: "#DD8E2E"), lineWidth: 1)
                                    )
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                
            }
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear { 
            submitAndLoad() 
            // Get room details to get property ID
            loadRoomDetails()
        }
        .sheet(isPresented: $showSafari) {
            SafariView(url: URL(string: "https://bookme.name/JayaKaramchandani/discovery-call-home-vastu-visit-online-session")!)
        }
        .fullScreenCover(isPresented: $navigateToHomeAnalyze) {
            HomeAnalyzeView(selectedPropertyType: "residential", propertyId: roomPropertyId)
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            // Top row with back button, centered logo, and action buttons
            HStack {
                // Back button on left
                Button(action: { 
                    // Set flag to false to prevent navigation to HomeAnalyzeView
                    shouldNavigateToHome = false
                    presentationMode.wrappedValue.dismiss() 
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#4A2511"))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Logo in center
                Image("headerimage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                Spacer()
                
                // Notification bell
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                
                // Profile image
                Button(action: {}) {
                    ProfileImageView(size: 40, lineWidth: 2)
                }
                .buttonStyle(.plain)
                 
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Second row with title completely left-aligned
            HStack {
                Text(roomName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // Vastu Gallery Card
    private var vastuGalleryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vastu Gallery")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            Text("View and manage all your Analyzed Spaces")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            HStack {
                Spacer()
                Button(action: {
                    navigateToGallery = true
                }) {
                    Text("View Property")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(Color(hex: "#DD8E2E"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 20)
        .fullScreenCover(isPresented: $navigateToGallery) {
            VastuGalleryView()
        }
    }
    
  
    // Helper function to determine score rating
    private func getScoreRating(percentage: Double) -> String {
        // Default to "Good" if the score is 0 (likely a new evaluation)
        if percentage == 0 {
            return "Good"
        } else if percentage >= 80 {
            return "Good"
        } else if percentage >= 60 {
            return "Average"
        } else {
            return "Needs Improvement"
        }
    }

    private func submitAndLoad() {
        isSubmitting = true
        errorMessage = nil
        
        // Add delay to ensure server has time to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.service.submitRoomAnswers(roomId: self.roomId, answers: self.answers) { res in
                switch res {
                case .success:
                    print("✅ Successfully submitted answers for room: \(self.roomId)")
                    
                    // Add delay before fetching score to ensure server has processed the answers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // After submitting, fetch the score
                        self.service.getRoomVastuScore(roomId: self.roomId) { res2 in
                            DispatchQueue.main.async {
                                self.isSubmitting = false
                                switch res2 {
                                case .success(let scoreResp):
                                    print("✅ Successfully received score data: \(scoreResp.data.displayPercentage)%")
                                    self.score = scoreResp.data
                                case .failure(let err):
                                    print("❌ Failed to get score: \(err)")
                                    // Provide more user-friendly error message
                                    if err.localizedDescription.contains("decode") {
                                        self.errorMessage = "Unable to process the score data. Please try again."
                                    } else {
                                        self.errorMessage = "Error loading score: \(err.localizedDescription)"
                                    }
                                }
                            }
                        }
                    }
                case .failure(let err):
                    print("❌ Failed to submit answers: \(err)")
                    DispatchQueue.main.async {
                        self.isSubmitting = false
                        self.errorMessage = "Failed to submit answers: \(err.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // Load room details to get property ID for HomeAnalyzeView
    private func loadRoomDetails() {
        service.getRoomDetails(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let roomData):
                    // Store the property ID for later use
                    self.roomPropertyId = roomData.propertyId
                    print("📋 Got property ID for room: \(self.roomPropertyId)")
                case .failure(let error):
                    print("❌ Failed to get room details: \(error)")
                }
            }
        }
    }
}
