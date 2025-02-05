import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    private var isPasswordMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Join the Kello community")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            // Error message
            if let error = viewModel.error {
                ErrorView(error: error)
            }
            
            // Form fields
            VStack(spacing: 16) {
                AuthTextField(
                    title: "Email",
                    text: $email,
                    icon: "envelope"
                )
                
                AuthTextField(
                    title: "Password",
                    text: $password,
                    icon: "lock",
                    isSecure: true
                )
                
                AuthTextField(
                    title: "Confirm Password",
                    text: $confirmPassword,
                    icon: "lock",
                    isSecure: true
                )
                
                // Password match indicator
                if !password.isEmpty || !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: isPasswordMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isPasswordMatch ? .green : .red)
                        Text(isPasswordMatch ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                            .foregroundColor(isPasswordMatch ? .green : .red)
                    }
                    .padding(.horizontal)
                }
            }
            
            // Sign up button
            AuthButton(
                title: "Create Account",
                action: signUp,
                isLoading: viewModel.isLoading
            )
            .disabled(!isPasswordMatch)
            .padding(.top, 24)
            
            // Back to sign in
            Button("Already have an account? Sign In") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
            .padding(.top, 16)
            
            Spacer()
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func signUp() {
        guard isPasswordMatch else { return }
        Task {
            await viewModel.signUp(email: email, password: password)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
} 