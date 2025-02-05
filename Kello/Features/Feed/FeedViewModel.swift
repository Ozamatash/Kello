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
    
    // Filters
    @Published var selectedTimeFilter: CookingTimeFilter?
    @Published var selectedCuisine: String?
    
    // Like state tracking
    @Published var likedRecipeIds: Set<String> = []
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, authViewModel: AuthViewModel) {
        self.modelContext = modelContext
        self.authViewModel = authViewModel
        Task {
            await loadLikedRecipes()
        }
    }
    
    // MARK: - Public Methods
    
    @MainActor
    private func loadLikedRecipes() async {
        if let userProfile = await authViewModel.userProfile {
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
        
        print("DEBUG: Loading initial recipes with filters - timeFilter: \(String(describing: selectedTimeFilter)), cuisine: \(String(describing: selectedCuisine))")
        isLoading = true
        do {
            recipes = try await firebaseService.filterRecipes(
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            print("DEBUG: Loaded \(recipes.count) recipes")
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
            let newRecipes = try await firebaseService.filterMoreRecipes(
                after: lastRecipe,
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            recipes.append(contentsOf: newRecipes)
            error = nil
        } catch {
            self.error = error
            print("Error loading more recipes: \(error)")
        }
        isLoading = false
    }
    
    func applyFilters(timeFilter: CookingTimeFilter?, cuisine: String?) {
        print("DEBUG: Applying filters - timeFilter: \(String(describing: timeFilter)), cuisine: \(String(describing: cuisine))")
        selectedTimeFilter = timeFilter
        selectedCuisine = cuisine
        Task { @MainActor in
            await loadInitialRecipes()
        }
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
        let recipe = recipes[index]
        // TODO: Implement share functionality
        // This will be implemented when we add UIActivityViewController integration
    }
} 