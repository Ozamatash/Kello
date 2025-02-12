import SwiftUI

struct SignInView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingResetPassword = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Logo and welcome text
                    VStack(spacing: 16) {
                        // App logo
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "flame")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.bottom, 8)
                        
                        Text("Welcome to Kello")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your personal cooking companion")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 40)
                    
                    // Error message
                    if let error = viewModel.error {
                        ErrorView(error: error)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Sign in form
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
                        
                        // Forgot password button
                        Button {
                            showingResetPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, -8)
                    }
                    
                    // Sign in buttons
                    VStack(spacing: 16) {
                        AuthButton(
                            title: "Sign In",
                            action: signIn,
                            isLoading: viewModel.isLoading
                        )
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Sign up button
                    VStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Create Account") {
                            showingSignUp = true
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    }
                    .font(.subheadline)
                }
                .padding(24)
                .frame(minHeight: geometry.size.height)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingResetPassword) {
            ResetPasswordView()
                .environmentObject(viewModel)
        }
    }
    
    private func signIn() {
        Task {
            await viewModel.signIn(email: email, password: password)
        }
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(AuthViewModel())
    }
} 