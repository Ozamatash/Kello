import SwiftUI

// MARK: - Design System

private enum AuthTheme {
    static let primaryColor = Color.accentColor
    static let errorColor = Color.red
    static let successColor = Color.green
    static let textFieldBackground = Color(.systemBackground)
    static let borderColor = Color(.systemGray4)
    static let shadowColor = Color.black.opacity(0.05)
    
    static let cornerRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 56
    static let iconSize: CGFloat = 20
    static let spacing: CGFloat = 20
}

// MARK: - Text Field

struct AuthTextField: View {
    let title: String
    let text: Binding<String>
    let icon: String
    var isSecure: Bool = false
    @State private var isEditing = false
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field label
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            // Text field container
            HStack(spacing: 12) {
                // Leading icon
                Image(systemName: icon)
                    .font(.system(size: AuthTheme.iconSize))
                    .foregroundColor(isEditing ? AuthTheme.primaryColor : .secondary)
                
                // Text input
                Group {
                    if isSecure {
                        Group {
                            if showPassword {
                                TextField(title, text: text)
                            } else {
                                SecureField(title, text: text)
                            }
                        }
                    } else {
                        TextField(title, text: text)
                    }
                }
                .textContentType(isSecure ? .oneTimeCode : .emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                // Trailing icon for password fields
                if isSecure {
                    Button {
                        withAnimation {
                            showPassword.toggle()
                        }
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: AuthTheme.iconSize - 2))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: AuthTheme.buttonHeight)
            .padding(.horizontal, 16)
            .background(AuthTheme.textFieldBackground)
            .cornerRadius(AuthTheme.cornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: AuthTheme.cornerRadius)
                    .stroke(isEditing ? AuthTheme.primaryColor : AuthTheme.borderColor, lineWidth: 1)
            }
            .shadow(color: AuthTheme.shadowColor, radius: 8, y: 4)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = true
            }
        }
    }
}

// MARK: - Button

struct AuthButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .primary
    @Environment(\.isEnabled) private var isEnabled
    
    enum ButtonStyle {
        case primary, secondary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .white
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .accentColor
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .contentTransition(.opacity)
                    .opacity(isLoading ? 0.5 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AuthTheme.buttonHeight)
            .background {
                RoundedRectangle(cornerRadius: AuthTheme.cornerRadius, style: .continuous)
                    .fill(style.backgroundColor)
                    .opacity(isEnabled ? 1 : 0.5)
            }
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: AuthTheme.cornerRadius)
                        .stroke(AuthTheme.primaryColor, lineWidth: 1)
                }
            }
            .foregroundColor(style.foregroundColor)
            .shadow(color: style == .primary ? AuthTheme.primaryColor.opacity(0.3) : .clear, 
                   radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: AuthTheme.iconSize))
                .foregroundColor(AuthTheme.errorColor)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(AuthTheme.errorColor)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(AuthTheme.errorColor.opacity(0.1))
        .cornerRadius(AuthTheme.cornerRadius)
    }
}

#Preview {
    VStack(spacing: AuthTheme.spacing) {
        AuthTextField(
            title: "Email",
            text: .constant("user@example.com"),
            icon: "envelope"
        )
        
        AuthTextField(
            title: "Password",
            text: .constant("password123"),
            icon: "lock",
            isSecure: true
        )
        
        AuthButton(
            title: "Sign In",
            action: {},
            isLoading: false
        )
        
        AuthButton(
            title: "Create Account",
            action: {},
            style: .secondary
        )
        
        ErrorView(error: NSError(domain: "", code: -1, 
                               userInfo: [NSLocalizedDescriptionKey: "Invalid email or password. Please try again."]))
    }
    .padding(24)
    .background(Color(.systemGroupedBackground))
} 