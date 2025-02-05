import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email to receive a password reset link")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Error message
                if let error = viewModel.error {
                    ErrorView(error: error)
                }
                
                // Email field
                AuthTextField(
                    title: "Email",
                    text: $email,
                    icon: "envelope"
                )
                
                // Reset button
                AuthButton(
                    title: "Send Reset Link",
                    action: resetPassword,
                    isLoading: viewModel.isLoading
                )
                .padding(.top, 24)
                
                Spacer()
            }
            .padding()
            .alert("Reset Link Sent", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Check your email for instructions to reset your password.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        Task {
            await viewModel.resetPassword(email: email)
            showingConfirmation = true
        }
    }
}

#Preview {
    ResetPasswordView()
} 