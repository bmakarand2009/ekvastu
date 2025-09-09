import SwiftUI

struct ConsultView: View {
    // State variables for accordion sections
    @State private var expandedSection: Int? = nil
    @State private var showingConfirmation = false
    
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
                    
                    // Accordion sections
                    VStack(spacing: 0) {
                        // Section 1: Get Clarity
                        accordionSection(
                            index: 1,
                            title: "Get Clarity (Initial Consultation)",
                            icon: "message",
                            content: {
                                if expandedSection == 1 {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("We'll answer your questions and lay the groundwork for a personalized plan.")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 5)
                                        
                                        Button(action: {
                                            expandedSection = 2
                                        }) {
                                            Text("Proceed to Pay")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(Color(hex: "#DD8E2E"))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 15)
                                }
                            }
                        )
                        
                        Divider()
                        
                        // Section 2: Secure Your Session
                        accordionSection(
                            index: 2,
                            title: "Secure Your Session",
                            icon: "checkmark.shield",
                            content: {
                                if expandedSection == 2 {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Pay a one-time fee to lock in your initial consultation")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 5)
                                        
                                        Button(action: {
                                            expandedSection = 3
                                        }) {
                                            Text("Pay Now")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(Color(hex: "#DD8E2E"))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 15)
                                }
                            }
                        )
                        
                        Divider()
                        
                        // Section 3: Pick Your Time
                        accordionSection(
                            index: 3,
                            title: "Pick Your Time",
                            icon: "clock",
                            content: {
                                if expandedSection == 3 {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("After you have secured your session you need to pick a date & time and connect with Jaya")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 5)
                                        
                                        Button(action: {
                                            showingConfirmation = true
                                        }) {
                                            Text("Book Now")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 20)
                                                .background(Color(hex: "#DD8E2E"))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .padding(.horizontal, 15)
                                    .padding(.bottom, 15)
                                }
                            }
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 80) // Space for bottom navigation
                }
                .padding(.vertical, 15)
            }
        }
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Consultation Scheduled"),
                message: Text("Your consultation with Jaya has been scheduled. We'll send you a confirmation email shortly."),
                dismissButton: .default(Text("OK"))
            )
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
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 35)
                .foregroundColor(Color(hex: "#DD8E2E"))
            
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
    
    // MARK: - Accordion Section
    private func accordionSection<Content: View>(index: Int, title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedSection == index {
                        // If already expanded, do nothing (keep it expanded)
                    } else {
                        expandedSection = index
                    }
                }
            }) {
                HStack(spacing: 15) {
                    Image(systemName: icon)
                        .foregroundColor(expandedSection == index ? Color(hex: "#DD8E2E") : .gray)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: expandedSection == index ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content area
            content()
        }
    }
}
