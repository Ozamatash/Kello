import Foundation
import SwiftData
import Combine

@Observable
class FeedViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let firebaseService = FirebaseService.shared
    
    var recipes: [Recipe] = []
    var isLoading = false
    var error: Error?
    
    // Filters
    var selectedCuisineType: String?
    var maxCookingTime: Int?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func loadInitialRecipes() async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            recipes = try await firebaseService.fetchRecipes(
                cuisineType: selectedCuisineType,
                maxCookingTime: maxCookingTime
            )
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
            let newRecipes = try await firebaseService.fetchMoreRecipes(after: lastRecipe)
            recipes.append(contentsOf: newRecipes)
            error = nil
        } catch {
            self.error = error
            print("Error loading more recipes: \(error)")
        }
        isLoading = false
    }
    
    func applyFilters(cuisineType: String?, maxTime: Int?) {
        selectedCuisineType = cuisineType
        maxCookingTime = maxTime
        Task { @MainActor in
            await loadInitialRecipes()
        }
    }
    
    @MainActor
    func likeRecipe(at index: Int) async throws {
        guard index < recipes.count else { return }
        let recipe = recipes[index]
        
        try await firebaseService.likeRecipe(recipe.id)
        recipes[index].likes += 1
    }
    
    func shareRecipe(at index: Int) {
        guard index < recipes.count else { return }
        let recipe = recipes[index]
        // TODO: Implement share functionality
        // This will be implemented when we add UIActivityViewController integration
    }
} 