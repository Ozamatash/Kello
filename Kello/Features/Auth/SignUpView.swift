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
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join the Kello community and start sharing your recipes")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 20)
                    
                    // Error message
                    if let error = viewModel.error {
                        ErrorView(error: error)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Sign up form
                    VStack(spacing: 20) {
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
                            HStack(spacing: 8) {
                                Image(systemName: isPasswordMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isPasswordMatch ? .green : .red)
                                    .imageScale(.small)
                                
                                Text(isPasswordMatch ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(isPasswordMatch ? .green : .red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                        }
                    }
                    
                    // Sign up buttons
                    VStack(spacing: 16) {
                        AuthButton(
                            title: "Create Account",
                            action: signUp,
                            isLoading: viewModel.isLoading
                        )
                        .disabled(!isPasswordMatch)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Sign in link
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? ")
                            .foregroundColor(.secondary) +
                        Text("Sign In")
                            .foregroundColor(.accentColor)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                }
                .padding(24)
                .frame(minHeight: geometry.size.height)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
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
            .environmentObject(AuthViewModel())
    }
} 