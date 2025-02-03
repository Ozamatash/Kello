import Foundation
import SwiftData
import Combine

@Observable
class FeedViewModel {
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared
    
    var recipes: [Recipe] = []
    var currentIndex: Int = 0
    var isLoading = false
    var error: Error?
    
    // Filters
    var selectedCuisineType: String?
    var maxCookingTime: Int?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
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
              !recipes.isEmpty else { return }
        
        isLoading = true
        do {
            let newRecipes = try await firebaseService.fetchMoreRecipes(
                after: recipes.last!
            )
            recipes.append(contentsOf: newRecipes)
            error = nil
        } catch {
            self.error = error
            print("Error loading more recipes: \(error)")
        }
        isLoading = false
    }
    
    func applyFilters(cuisineType: String?, maxTime: Int?) {
        self.selectedCuisineType = cuisineType
        self.maxCookingTime = maxTime
        Task {
            await loadInitialRecipes()
        }
    }
    
    func likeRecipe(at index: Int) {
        guard index < recipes.count else { return }
        let recipe = recipes[index]
        
        Task {
            do {
                try await firebaseService.likeRecipe(recipe.id)
                // Update local state
                await MainActor.run {
                    recipes[index].likes += 1
                }
            } catch {
                print("Error liking recipe: \(error)")
            }
        }
    }
    
    func shareRecipe(at index: Int) {
        guard index < recipes.count else { return }
        // TODO: Implement share functionality using UIActivityViewController
    }
} 