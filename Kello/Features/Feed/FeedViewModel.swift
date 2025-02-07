import Foundation
import SwiftData
import Combine

class FeedViewModel: ObservableObject {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let firebaseService = FirebaseService.shared
    private let authViewModel: AuthViewModel
    
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // Like state tracking
    @Published var likedRecipeIds: Set<String> = []
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, authViewModel: AuthViewModel) {
        self.modelContext = modelContext
        self.authViewModel = authViewModel
        
        // Initialize async task to load liked recipes
        Task { @MainActor in
            await loadLikedRecipes()
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    private func loadLikedRecipes() async {
        if let userProfile = authViewModel.userProfile {
            likedRecipeIds = Set(userProfile.likedRecipes)
        }
    }
    
    @MainActor
    func isRecipeLiked(_ recipeId: String) -> Bool {
        return likedRecipeIds.contains(recipeId)
    }
    
    @MainActor
    func loadInitialRecipes() async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            recipes = try await firebaseService.filterRecipes()
            error = nil
        } catch {
            self.error = error
            print("Error loading recipes: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func loadMoreRecipes() async {
        guard !isLoading,
              let lastRecipe = recipes.last else { return }
        
        isLoading = true
        do {
            let newRecipes = try await firebaseService.filterMoreRecipes(after: lastRecipe)
            recipes.append(contentsOf: newRecipes)
            error = nil
        } catch {
            self.error = error
            print("Error loading more recipes: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func likeRecipe(at index: Int) async throws {
        guard index < recipes.count else { return }
        let recipe = recipes[index]
        
        if isRecipeLiked(recipe.id) {
            // Unlike
            try await firebaseService.unlikeRecipe(recipe.id)
            await authViewModel.unlikeRecipe(recipe.id)
            recipes[index].likes -= 1
            likedRecipeIds.remove(recipe.id)
        } else {
            // Like
            try await firebaseService.likeRecipe(recipe.id)
            await authViewModel.likeRecipe(recipe.id)
            recipes[index].likes += 1
            likedRecipeIds.insert(recipe.id)
        }
    }
    
    func shareRecipe(at index: Int) {
        guard index < recipes.count else { return }
        let _ = recipes[index]
        // TODO: Implement share functionality
        // This will be implemented when we add UIActivityViewController integration
    }
} 