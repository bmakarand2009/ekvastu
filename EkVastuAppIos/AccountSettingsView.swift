import SwiftUI

struct AccountSettingsView: View {
    @ObservedObject var authManager = AuthenticationManager.shared
    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    @State private var isDeleting = false
    @State private var isResetting = false
    @State private var deleteError: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#4A2511"))
                    
                    Text("Manage your account and data")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                Spacer()
                
                // Settings Options
                VStack(spacing: 15) {
                    // Reset App Data
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Reset App Data")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .disabled(isResetting)
                    
                    // Delete Account
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Account Permanently")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .disabled(isDeleting)
                }
                .padding(.horizontal)
                
                // Error message
                if let error = deleteError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Info text
                VStack(spacing: 8) {
                    Text("⚠️ Warning")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Deleting your account will permanently remove all your data including user details, property addresses, and room photos. This action cannot be undone.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .background(Color.gray.opacity(0.1))
            .navigationBarHidden(true)
        }
        .alert("Reset App Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAppData()
            }
        } message: {
            Text("This will clear all your local data and sign you out. You'll need to sign in again and re-enter your information.")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your Firebase account and all associated data. This action cannot be undone.")
        }
    }
    
    private func resetAppData() {
        isResetting = true
        deleteError = nil
        
        authManager.resetAppToFreshState { success in
            DispatchQueue.main.async {
                isResetting = false
                if success {
                    // Navigate back to sign in
                    presentationMode.wrappedValue.dismiss()
                } else {
                    deleteError = "Failed to reset app data"
                }
            }
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        deleteError = nil
        
        authManager.deleteUserAccount { success, error in
            DispatchQueue.main.async {
                isDeleting = false
                if success {
                    // Account deleted successfully, navigate to sign in
                    presentationMode.wrappedValue.dismiss()
                } else {
                    deleteError = error?.localizedDescription ?? "Failed to delete account"
                }
            }
        }
    }
}

struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettingsView()
    }
}
