import SwiftUI

struct SignInView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingResetPassword = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo and welcome text
                VStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Welcome to Kello")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Error message
                if let error = viewModel.error {
                    ErrorView(error: error)
                }
                
                // Email and password fields
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
                }
                
                // Forgot password button
                Button("Forgot Password?") {
                    showingResetPassword = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding(.top, 8)
                
                // Sign in button
                AuthButton(
                    title: "Sign In",
                    action: signIn,
                    isLoading: viewModel.isLoading
                )
                .padding(.top, 24)
                
                // Sign up button
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .foregroundColor(.accentColor)
                }
                .font(.subheadline)
                .padding(.top, 16)
                
                Spacer()
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func signIn() {
        Task {
            await viewModel.signIn(email: email, password: password)
        }
    }
}

#Preview {
    SignInView()
} 