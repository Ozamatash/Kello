import Foundation
import FirebaseAuth

class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    
    init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            self?.user = user
        }
    }
} 