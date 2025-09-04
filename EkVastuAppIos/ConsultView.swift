import SwiftUI

struct ConsultView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var message = ""
    @State private var selectedConsultationType = "General Vastu"
    @State private var showingConfirmation = false
    
    let consultationTypes = ["General Vastu", "Home Vastu", "Office Vastu", "Property Vastu", "Commercial Space"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                // Logo at the top
                Image("headerimage")
                    .frame(width: 78)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                
                Text("Consult with Vastu Expert")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Fill in the details below to schedule a consultation with our Vastu experts.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    
                    // Consultation Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Consultation Type")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Picker("Consultation Type", selection: $selectedConsultationType) {
                            ForEach(consultationTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField("Enter your name", text: $name)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Phone Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextField("Enter your phone number", text: $phone)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Message Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        TextEditor(text: $message)
                            .frame(height: 120)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Submit Button
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Text("Submit Request")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#4A2511"))
                            .cornerRadius(8)
                    }
                    .padding(.top, 10)
                    .alert(isPresented: $showingConfirmation) {
                        Alert(
                            title: Text("Request Submitted"),
                            message: Text("Thank you for your consultation request. Our Vastu expert will contact you shortly."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

struct ConsultView_Previews: PreviewProvider {
    static var previews: some View {
        ConsultView()
    }
}
