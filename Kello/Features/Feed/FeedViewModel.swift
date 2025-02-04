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
    var selectedTimeFilter: CookingTimeFilter?
    var selectedCuisine: String?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
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