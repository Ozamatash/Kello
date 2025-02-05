import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Email Authentication
    
    func signUp(email: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        try await createUserProfile(for: result.user)
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        try await updateLastLoginTimestamp(for: result.user)
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - User Profile Management
    
    private func createUserProfile(for user: User) async throws {
        let profile = UserProfile(from: user)
        try await db.collection("users").document(user.uid).setData(from: profile)
    }
    
    private func updateLastLoginTimestamp(for user: User) async throws {
        try await db.collection("users").document(user.uid).updateData([
            "lastLoginAt": Date()
        ])
    }
    
    // MARK: - User Data Operations
    
    func getUserProfile() async throws -> UserProfile? {
        guard let user = auth.currentUser else { return nil }
        let snapshot = try await db.collection("users").document(user.uid).getDocument()
        return try snapshot.data(as: UserProfile.self)
    }
    
    func updateUserLikedRecipes(add recipeId: String) async throws {
        guard let user = auth.currentUser else { return }
        try await db.collection("users").document(user.uid).updateData([
            "likedRecipes": FieldValue.arrayUnion([recipeId])
        ])
    }
    
    func updateUserUnlikedRecipes(remove recipeId: String) async throws {
        guard let user = auth.currentUser else { return }
        try await db.collection("users").document(user.uid).updateData([
            "likedRecipes": FieldValue.arrayRemove([recipeId])
        ])
    }
    
    func updateUserBookmarkedRecipes(add recipeId: String) async throws {
        guard let user = auth.currentUser else { return }
        try await db.collection("users").document(user.uid).updateData([
            "bookmarkedRecipes": FieldValue.arrayUnion([recipeId])
        ])
    }
    
    func updateUserUnbookmarkedRecipes(remove recipeId: String) async throws {
        guard let user = auth.currentUser else { return }
        try await db.collection("users").document(user.uid).updateData([
            "bookmarkedRecipes": FieldValue.arrayRemove([recipeId])
        ])
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try auth.signOut()
    }
} 