import SwiftUI
import Combine
import SafariServices

struct RemediesView: View {
    @StateObject private var viewModel = RemediesViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with logo
                HStack {
                    Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    Spacer()
                    
                    Button(action: {
                        // Notification action
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                    
                    // Profile image with built-in action sheet
                    ProfileImageView(size: 40, lineWidth: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Title
                HStack {
                    Text("Remedies Library")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    Spacer()
                }
                
                
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack {
                        Text("Error loading remedies")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Button("Retry") {
                            viewModel.fetchRemedies()
                        }
                        .padding()
                        .background(Color(hex: "#4A2511"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top)
                        .buttonStyle(.plain)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Remedies list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(viewModel.remedies) { remedy in
                                RemedyCard(remedy: remedy)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical)
                    }
                }
                
                Spacer()
                
              
            }
            .background(Color(hex: "#FFF5EA").edgesIgnoringSafeArea(.all))
            .onAppear {
                viewModel.fetchRemedies()
            }
        }
    }
    
    // filteredRemedies function removed - unused
}

struct RemedyCard: View {
    let remedy: Remedy
    @State private var isShowingDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left content (text and button)
            VStack(alignment: .leading) {
                Text(remedy.name)
                    .font(.system(size: 17))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#333333"))
                
                Text(remedy.shortDesc)
                    .font(.body)
                    .foregroundColor(Color(hex: "#8B7355"))
                    .lineLimit(4)
                
                Button(action: {
                    isShowingDetails = true
                }) {
                    Text("View Steps")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#333333"))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "#FFE4C4").opacity(0.8))
                        .cornerRadius(25)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Right content (image)
            AsyncImage(url: URL(string: remedy.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 100, height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                @unknown default:
                    EmptyView()
                }
            }
        }
        .padding(10)
        .background(Color(hex: "#FFF5EA"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical, 8)
        .onTapGesture {
            isShowingDetails = true
        }
        // Use a hidden NavigationLink for compatibility with NavigationView
        .background(
            NavigationLink(destination: RemedyDetailView(remedy: remedy), isActive: $isShowingDetails) {
                EmptyView()
            }
            .hidden()
        )
    }
}

// TabBarButton removed - unused

struct RemedyDetailView: View {
    let remedy: Remedy
    @State private var instructionSteps: [String] = []
    @State private var showSafari = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Disclaimer banner with Book Consultation button
                ZStack {
                    // Background layer with image
                    HStack {
                        Spacer()
                        Image("remedydetails")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180) // Reduced size
                            .opacity(0.7) // Make image more subtle
                    }
                    .padding(.trailing, -20)
                    
                    // Content layer (text and button)
                    VStack(alignment: .leading, spacing: 16) {
                        // Title with exclamation mark
                        HStack(alignment: .top, spacing: 8) {
                            Text("!")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: "#3A1F0F"))
                            
                            Text("These Remedies are genral suggestions")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(hex: "#3A1F0F"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Description text
                        Text("These remedies are general suggestions. For in-depth reasoning and personalized solutions, consider booking a consultation with Jaya.")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#333333"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.6) // Limit width to avoid overlapping with image
                        
                        // Book Consultation button
                        Button(action: {
                            // Open in-app browser with booking URL
                            showSafari = true
                        }) {
                            Text("Coffee With Jaya")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 260, height: 40)
                                .background(Color(hex: "#3A1F0F"))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                   
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Remedy name
                Text(remedy.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#333333"))
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Long description
                Text(remedy.longDescription)
                    .font(.body)
                    .foregroundColor(Color(hex: "#666666"))
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Instructions section
                Text("Instructions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#333333"))
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Instruction steps
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(instructionSteps.indices, id: \.self) { index in
                        InstructionStepView(stepNumber: index + 1, description: instructionSteps[index])
                    }
                }
                .padding(.top, 5)
                
                // Remedy image at the bottom
                if let imageUrl = URL(string: remedy.image) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.1))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        case .failure:
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.1))
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 30))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(hex: "#FFF5EA").edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 8) {
                    // Back button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#333333"))
                    }
                    .buttonStyle(.plain)
                    
                    // Title label (not a button)
                    Text("Remedy Details")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#333333"))
                }
            }
        }
        .onAppear {
            // Parse instructions on appear
            parseInstructions()
        }
        .sheet(isPresented: $showSafari) {
            SafariView(url: URL(string: "https://bookme.name/JayaKaramchandani/discovery-call-home-vastu-visit-online-session")!)
        }
    }
    
    private func parseInstructions() {
        // Since instructions are now an array, we can use them directly
        // Process each instruction to remove numbering if present
        instructionSteps = remedy.instructions.map { instruction in
            // Remove numbering if present (e.g., "1. ", "2. ")
            if let range = instruction.range(of: "^\\d+\\.\\s*", options: .regularExpression) {
                return String(instruction[range.upperBound...])
            }
            return instruction
        }
        
        // Display the exact number of steps available in the instructions array
        // No need to limit as we're showing exactly what the API provides
    }
}

// StepView removed - unused

struct InstructionStepView: View {
    let stepNumber: Int
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number circle with outline
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Step number and title
                Text("Step \(stepNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#333333"))
                
                // Step description
                Text(description)
                    .font(.body)
                    .foregroundColor(Color(hex: "#8B7355"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2)
        .padding(.horizontal)
    }
}

class RemediesViewModel: ObservableObject {
    @Published var remedies: [Remedy] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func fetchRemedies() {
        isLoading = true
        error = nil
        
        // Create mock data for testing
        createMockRemedies()
    }
    
    // Create mock remedies data for testing
    private func createMockRemedies() {
        let mockRemedies = [
            Remedy(
                id: "1",
                name: "Crystal Grid for Enhanced Energy",
                shortDesc: "A harmonious arrangement of crystals to balance energy flow.",
                longDescription: "This remedy addresses energy imbalances in the home, promoting harmony and well-being. It involves creating a crystal grid in a specific area of your home to redirect and balance energy flow.",
                instructions: [
                    "1. Place a clear quartz crystal in the center of the grid.",
                    "2. Surround the central crystal with six amethyst points.",
                    "3. Activate the grid with intention and positive affirmations."
                ],
                image: "https://images.unsplash.com/photo-1598965402089-897ce52e8355?q=80&w=2936&auto=format&fit=crop"
            ),
            Remedy(
                id: "2",
                name: "Lemon Water Remedy",
                shortDesc: "Place lemon water to absorb negativity",
                longDescription: "Placing a bowl of lemon water in your home or workspace is believed to absorb negative energy and uplift the environment. The lemon acts as a natural purifier, bringing freshness and clarity.",
                instructions: [
                    "1. Fill a glass bowl with clean water",
                    "2. Slice one fresh lemon and add to the bowl",
                    "3. Place in a central or visible area",
                    "4. Replace daily for best results"
                ],
                image: "https://images.unsplash.com/photo-1582979512210-99b6a53386f9?q=80&w=3387&auto=format&fit=crop"
            ),
            Remedy(
                id: "3",
                name: "Mirror Correction",
                shortDesc: "Proper mirror placement for energy flow",
                longDescription: "Mirrors can redirect and amplify energy flow in your home. Proper placement according to Vastu can enhance positive vibrations and correct energy imbalances.",
                instructions: [
                    "1. Remove mirrors facing the bed",
                    "2. Place mirrors on north or east walls",
                    "3. Ensure mirrors reflect pleasant views"
                ],
                image: "https://images.unsplash.com/photo-1618220252344-8ec99ec624b1?q=80&w=3000&auto=format&fit=crop"
            ),
            Remedy(
                id: "4",
                name: "Salt Lamp Placement",
                shortDesc: "Place salt lamps to purify energy",
                longDescription: "Himalayan salt lamps can help neutralize negative energies and purify the air in your space. They work well in areas with electronic devices.",
                instructions: [
                    "1. Place in the southwest corner",
                    "2. Keep lamp on for at least 6 hours daily",
                    "3. Clean regularly with dry cloth"
                ],
                image: "https://images.unsplash.com/photo-1563245372-f21724e3856d?q=80&w=3129&auto=format&fit=crop"
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.remedies = mockRemedies
            self?.isLoading = false
            print("Successfully loaded \(mockRemedies.count) mock remedies")
        }
    }
}

// Using existing SafariView implementation from SafariView.swift
 
