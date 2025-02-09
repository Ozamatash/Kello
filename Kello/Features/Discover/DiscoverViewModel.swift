import Foundation
import Combine

// MARK: - Filters

enum CookingTimeFilter: Int, CaseIterable, Identifiable {
    case quick = 0
    case medium = 1
    case long = 2
    case extended = 3
    
    var id: Int { rawValue }
    
    var displayText: String {
        switch self {
        case .quick: return "< 15 min"
        case .medium: return "15-30 min"
        case .long: return "30-60 min"
        case .extended: return "60+ min"
        }
    }
    
    var range: (min: Int, max: Int) {
        switch self {
        case .quick: return (0, 14)
        case .medium: return (15, 30)
        case .long: return (31, 60)
        case .extended: return (61, Int.max)
        }
    }
}

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case dessert = "Dessert"
    
    var id: String { rawValue }
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var hasMoreRecipes = true
    
    @Published var selectedTimeFilter: CookingTimeFilter?
    @Published var selectedCuisine: String?
    @Published var selectedMealType: MealType?
    
    let availableCuisines = [
        "Italian", "Chinese", "Japanese", "Mexican", "Indian",
        "Thai", "French", "American", "Mediterranean", "Korean",
        "Vietnamese", "Spanish", "Greek", "Middle Eastern"
    ].sorted()
    
    var hasActiveFilters: Bool {
        selectedTimeFilter != nil || selectedCuisine != nil || selectedMealType != nil
    }
    
    private let pageSize = 50
    private var lastLoadedRecipe: Recipe?
    private let firebaseService = FirebaseService.shared
    private let searchService = RecipeSearchService()
    private var loadingTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        loadRecipes()
    }
    
    // MARK: - Public Methods
    
    func selectTimeFilter(_ filter: CookingTimeFilter) {
        selectedTimeFilter = selectedTimeFilter == filter ? nil : filter
        loadRecipes()
    }
    
    func selectCuisine(_ cuisine: String) {
        selectedCuisine = selectedCuisine == cuisine ? nil : cuisine
        loadRecipes()
    }
    
    func selectMealType(_ type: MealType) {
        selectedMealType = selectedMealType == type ? nil : type
        loadRecipes()
    }
    
    func clearFilters() {
        selectedTimeFilter = nil
        selectedCuisine = nil
        selectedMealType = nil
        loadRecipes()
    }
    
    func clearSearch() {
        loadRecipes()
    }
    
    func performSearch(_ searchTerm: String) async {
        loadingTask?.cancel()
        recipes = []
        
        do {
            // First perform semantic search
            let searchResults = try await searchService.searchRecipes(searchTerm: searchTerm)
            
            // Then apply filters if any are active
            if hasActiveFilters {
                recipes = searchResults.filter { recipe in
                    var matches = true
                    
                    if let timeFilter = selectedTimeFilter {
                        matches = matches && recipe.cookingTime >= timeFilter.range.min && recipe.cookingTime < timeFilter.range.max
                    }
                    
                    if let cuisine = selectedCuisine {
                        matches = matches && recipe.cuisineType == cuisine
                    }
                    
                    if let mealType = selectedMealType {
                        matches = matches && recipe.mealType == mealType.rawValue
                    }
                    
                    return matches
                }
            } else {
                recipes = searchResults
            }
            
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func loadMoreRecipes() async {
        guard !isLoading,
              hasMoreRecipes,
              let lastRecipe = lastLoadedRecipe else { return }
        
        isLoading = true
        do {
            let newRecipes = try await firebaseService.filterMoreRecipes(
                after: lastRecipe,
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine,
                mealType: selectedMealType?.rawValue,
                limit: pageSize
            )
            
            // Append new recipes without modifying existing ones
            await MainActor.run {
                // Create a set of existing recipe IDs for efficient lookup
                let existingIds = Set(recipes.map { $0.id })
                
                // Filter out any recipes that already exist in our list
                let uniqueNewRecipes = newRecipes.filter { !existingIds.contains($0.id) }
                
                recipes.append(contentsOf: uniqueNewRecipes)
                lastLoadedRecipe = recipes.last
                // Check if we got less unique recipes than requested, might need to load more
                hasMoreRecipes = uniqueNewRecipes.count == pageSize || newRecipes.count == pageSize
                error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    private func loadRecipes() {
        loadingTask?.cancel()
        recipes = []
        lastLoadedRecipe = nil
        hasMoreRecipes = true
        
        loadingTask = Task {
            // Debounce rapid filter changes
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            isLoading = true
            do {
                recipes = try await firebaseService.filterRecipes(
                    timeFilter: selectedTimeFilter,
                    cuisine: selectedCuisine,
                    mealType: selectedMealType?.rawValue,
                    limit: pageSize
                )
                lastLoadedRecipe = recipes.last
                hasMoreRecipes = recipes.count == pageSize
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
} 