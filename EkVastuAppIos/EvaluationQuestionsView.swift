import SwiftUI

struct EvaluationQuestionsView: View {
    let roomId: String
    let roomName: String

    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var questions: [RoomQuestion] = []
    @State private var answers: [String: String] = [:] // questionId -> answer
    @State private var showScore = false
    @State private var selectedOption: String? = nil
    @State private var showDropdown: [String: Bool] = [:] // Track dropdown state for each question
    @State private var navigateToHomeAnalyze = false
    @State private var roomPropertyId: String = "" // Store the room's property ID
    @State private var shouldNavigateToHome = true // Flag to control navigation after VastuScoreView

    private let service = VastuService.shared
    // Payload to present VastuScoreView with stable data
    struct ScorePayload: Identifiable {
        let id = UUID()
        let roomId: String
        let roomName: String
        let answers: [RoomAnswerItem]
    }
    @State private var scorePayload: ScorePayload? = nil

    var body: some View {
        ZStack {
            // Background color from the design
            Color(hex: "#FFF1E6").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with back button, logo, and profile
                header
                
                // Title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evaluation for \(roomName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    Text("Answer the following questions to get a quick Vastu analysis of your room.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else {
                    // Questions card
                    ScrollView {
                        VStack(spacing: 0) {
                            // White card containing all questions
                            VStack(spacing: 0) {
                                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                    questionView(question: question, index: index + 1)
                                    
                                    // Add divider between questions except for the last one
                                    if index < questions.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 20)
                            
                            // View Vastu Score button
                            Button(action: goToScore) {
                                Text("View Vastu Score")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(isAllAnswered ? Color(hex: "#DD8E2E") : Color.gray)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isAllAnswered)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .onAppear { loadQuestions() }
        .navigationBarHidden(true)
        // Present VastuScoreView with a stable payload to avoid empty answers
        .fullScreenCover(item: $scorePayload) { payload in
            VastuScoreView(roomId: payload.roomId, roomName: payload.roomName, answers: payload.answers, shouldNavigateToHome: $shouldNavigateToHome)
                .onDisappear {
                    if shouldNavigateToHome {
                        goToHomeAnalyze()
                    } else {
                        shouldNavigateToHome = true
                    }
                }
        }
        .fullScreenCover(isPresented: $navigateToHomeAnalyze) {
            HomeAnalyzeView(selectedPropertyType: "residential", propertyId: roomPropertyId)
        }
    }

    private var header: some View {
        HStack(spacing: 15) {
            Button(action: { 
                // Navigate to HomeAnalyzeView instead of dismissing
                goToHomeAnalyze()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }.buttonStyle(.plain)
            
            Spacer()
            
            // Logo in the center
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
            }.buttonStyle(.plain)
            
            // Profile image (match HomeAnalyzeView)
            Button(action: {}) {
                ProfileImageView(size: 40, lineWidth: 2)
            }
            .buttonStyle(.plain)
           
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }

    private func questionView(question: RoomQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text with number
            HStack(alignment: .top, spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 20, alignment: .leading)
                
                Text(question.question)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            
            // Answer options
            if question.type == "yes_no" {
                yesNoButtons(questionId: question.id)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 20)
            } else if question.type == "multiple_choice", let options = question.options {
                dropdownMenu(questionId: question.id, options: options)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 20)
            }
        }
    }

    private func yesNoButtons(questionId: String) -> some View {
        HStack(spacing: 10) {
            // No button
            Button(action: { answers[questionId] = "no" }) {
                Text("No")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(answers[questionId] == "no" ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(answers[questionId] == "no" ? Color(hex: "#DD8E2E") : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: answers[questionId] == "no" ? 0 : 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Yes button
            Button(action: { answers[questionId] = "yes" }) {
                Text("Yes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(answers[questionId] == "yes" ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(answers[questionId] == "yes" ? Color(hex: "#DD8E2E") : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: answers[questionId] == "yes" ? 0 : 1)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func dropdownMenu(questionId: String, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Custom dropdown menu
            Button(action: {
                // Toggle dropdown visibility
                withAnimation {
                    showDropdown[questionId] = !(showDropdown[questionId] ?? false)
                }
            }) {
                HStack {
                    Text(answers[questionId] ?? "Select an option")
                        .font(.system(size: 16))
                        .foregroundColor(answers[questionId] != nil ? .black : .gray)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(showDropdown[questionId] ?? false ? 180 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Dropdown options
            if showDropdown[questionId] ?? false {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            answers[questionId] = option
                            showDropdown[questionId] = false
                        }) {
                            HStack {
                                Text(option)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                if answers[questionId] == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#DD8E2E"))
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(answers[questionId] == option ? Color.gray.opacity(0.1) : Color.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if option != options.last {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .offset(y: 4)
                .zIndex(1)
            }
        }
    }

    private var isAllAnswered: Bool {
        !questions.isEmpty && questions.allSatisfy { answers[$0.id] != nil }
    }

    private func loadQuestions() {
        isLoading = true
        errorMessage = nil
        
        // First, get the room details to get the property ID
        service.getRoomDetails(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let roomData):
                    // Store the property ID for later use
                    self.roomPropertyId = roomData.propertyId
                    print("📋 Got property ID for room: \(self.roomPropertyId)")
                    
                    // Now load the questions
                    self.loadRoomQuestions()
                    
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = "Failed to get room details: \(error.localizedDescription)"
                    print("❌ Failed to get room details: \(error)")
                }
            }
        }
    }
    
    private func loadRoomQuestions() {
        service.getRoomQuestions(roomId: roomId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let resp):
                    self.questions = resp.data
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func goToScore() {
        // Build answers from current selections with normalization
        let items = questions.compactMap { q -> RoomAnswerItem? in
            guard let raw = answers[q.id]?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
            // Multiple choice stays as text; yes/no mapped to Yes/No text for now
            switch q.type {
            case "multiple_choice":
                return RoomAnswerItem(question_id: q.id, answer_text: raw)
            case "yes_no":
                let yesNo = raw.lowercased() == "yes" ? "Yes" : (raw.lowercased() == "no" ? "No" : raw)
                return RoomAnswerItem(question_id: q.id, answer_text: yesNo)
            default:
                return RoomAnswerItem(question_id: q.id, answer_text: raw)
            }
        }
        // Debug: log what we are about to send
        print("🧭 goToScore -> built answers count: \(items.count)")
        items.forEach { item in
            if let t = item.answer_text { print("  - \(item.question_id): text=\(t)") }
            if let v = item.answer_value { print("  - \(item.question_id): value=\(v)") }
        }
        
        // Present score only if we have answers
        if !items.isEmpty {
            let payload = ScorePayload(roomId: roomId, roomName: roomName, answers: items)
            // Assign payload first, then toggle the sheet
            self.scorePayload = payload
            DispatchQueue.main.async {
                self.showScore = true // retained if referenced elsewhere; not used for presentation now
            }
        }
    }
    
    // Navigate to HomeAnalyzeView
    private func goToHomeAnalyze() {
        navigateToHomeAnalyze = true
    }
}
