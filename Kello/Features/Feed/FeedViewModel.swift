import Foundation
import SwiftData
import Combine

@Observable
class FeedViewModel {
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    var recipes: [Recipe] = []
    var currentIndex: Int = 0
    var isLoading = false
    var error: Error?
    
    // Filters
    var selectedCuisineType: String?
    var maxCookingTime: Int?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadInitialRecipes()
    }
    
    func loadInitialRecipes() {
        // TODO: Implement Firebase fetch
        // For now, we'll use mock data
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            // Add mock data here when testing
        }
    }
    
    func loadMoreRecipes() {
        guard !isLoading else { return }
        // TODO: Implement pagination
    }
    
    func applyFilters(cuisineType: String?, maxTime: Int?) {
        self.selectedCuisineType = cuisineType
        self.maxCookingTime = maxTime
        loadInitialRecipes()
    }
    
    func likeRecipe(at index: Int) {
        guard index < recipes.count else { return }
        // TODO: Implement like functionality
    }
    
    func shareRecipe(at index: Int) {
        guard index < recipes.count else { return }
        // TODO: Implement share functionality
    }
} 