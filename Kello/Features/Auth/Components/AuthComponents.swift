import SwiftUI

struct AuthTextField: View {
    let title: String
    let text: Binding<String>
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: text)
            } else {
                TextField(title, text: text)
            }
        }
        .textFieldStyle(.plain)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        }
        .overlay(alignment: .leading) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .padding(.leading)
        }
        .padding(.horizontal)
    }
}

struct AuthButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .accentColor
            case .secondary:
                return .white
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return .accentColor
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary:
                return .clear
            case .secondary:
                return .accentColor
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style.borderColor, lineWidth: 1)
            }
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 20) {
        AuthTextField(
            title: "Email",
            text: .constant(""),
            icon: "envelope"
        )
        
        AuthTextField(
            title: "Password",
            text: .constant(""),
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
        
        ErrorView(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email address"]))
    }
    .padding()
} 