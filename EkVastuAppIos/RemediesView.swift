import SwiftUI
import Combine

struct RemediesView: View {
    @StateObject private var viewModel = RemediesViewModel()
    @State private var selectedFilter: RemedyFilterType = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with logo
                HStack {
                    Image("headerimage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    Spacer()
                    
                    Button(action: {
                        // Notification action
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        // Profile action
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
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
                
                // Filter tabs
                HStack(spacing: 20) {
                    ForEach(RemedyFilterType.allCases, id: \.self) { filterType in
                        VStack(spacing: 8) {
                            Text(filterType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(selectedFilter == filterType ? .black : .gray)
                            
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedFilter == filterType ? .black : .clear)
                        }
                        .onTapGesture {
                            selectedFilter = filterType
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Divider
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2))
                    .padding(.top, 8)
                
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
                    }
                    .padding()
                    Spacer()
                } else {
                    // Remedies list
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredRemedies) { remedy in
                                RemedyCard(remedy: remedy)
                            }
                        }
                        .padding()
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
    
    var filteredRemedies: [Remedy] {
        switch selectedFilter {
        case .all:
            return viewModel.remedies
        case .room:
            return viewModel.remedies.filter { $0.roomType != nil }
        case .issue:
            return viewModel.remedies.filter { $0.issueType != nil }
        }
    }
}

struct RemedyCard: View {
    let remedy: Remedy
    @State private var isShowingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(remedy.name)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(remedy.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Button(action: {
                    isShowingDetails = true
                }) {
                    Text("View Steps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                AsyncImage(url: URL(string: remedy.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .frame(width: 80, height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $isShowingDetails) {
            RemedyDetailView(remedy: remedy)
        }
    }
}

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? Color(hex: "#4A2511") : .gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? Color(hex: "#4A2511") : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct RemedyDetailView: View {
    let remedy: Remedy
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: remedy.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text(remedy.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(remedy.description)
                    .font(.body)
                    .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                Text("Steps")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ForEach(remedy.steps.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                    StepView(step: step)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(remedy.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StepView: View {
    let step: RemedyStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step \(step.stepNumber)")
                .font(.headline)
                .foregroundColor(Color(hex: "#4A2511"))
            
            Text(step.description)
                .font(.body)
            
            if let imageUrl = step.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .frame(height: 150)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
}

class RemediesViewModel: ObservableObject {
    @Published var remedies: [Remedy] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let remedyService = RemedyService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchRemedies() {
        isLoading = true
        error = nil
        
        remedyService.fetchRemedies()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] remedies in
                    self?.remedies = remedies
                }
            )
            .store(in: &cancellables)
    }
}
 
