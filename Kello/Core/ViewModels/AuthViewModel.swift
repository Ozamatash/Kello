import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var user: User?
    @Published var userProfile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    
    private let authService = AuthService.shared
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = stateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            try await authService.signUp(email: email, password: password)
            await loadUserProfile()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            await loadUserProfile()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        error = nil
        
        do {
            try await authService.resetPassword(email: email)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signOut() {
        error = nil
        
        do {
            try authService.signOut()
            userProfile = nil
        } catch {
            self.error = error
        }
    }
    
    // MARK: - User Profile Methods
    
    func loadUserProfile() async {
        do {
            userProfile = try await authService.getUserProfile()
        } catch {
            // Silently handle profile loading errors
        }
    }
    
    // MARK: - Recipe Interaction Methods
    
    func likeRecipe(_ recipeId: String) async {
        do {
            try await authService.updateUserLikedRecipes(add: recipeId)
            userProfile?.likedRecipes.append(recipeId)
        } catch {
            // Handle recipe interaction errors silently
        }
    }
    
    func unlikeRecipe(_ recipeId: String) async {
        do {
            try await authService.updateUserUnlikedRecipes(remove: recipeId)
            userProfile?.likedRecipes.removeAll { $0 == recipeId }
        } catch {
            // Handle recipe interaction errors silently
        }
    }
    
    func bookmarkRecipe(_ recipeId: String) async {
        do {
            try await authService.updateUserBookmarkedRecipes(add: recipeId)
            userProfile?.bookmarkedRecipes.append(recipeId)
        } catch {
            // Handle recipe interaction errors silently
        }
    }
    
    func unbookmarkRecipe(_ recipeId: String) async {
        do {
            try await authService.updateUserUnbookmarkedRecipes(remove: recipeId)
            userProfile?.bookmarkedRecipes.removeAll { $0 == recipeId }
        } catch {
            // Handle recipe interaction errors silently
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
                
                if user != nil {
                    await self?.loadUserProfile()
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
} 