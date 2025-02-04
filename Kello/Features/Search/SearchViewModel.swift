import Foundation
import Combine

enum CookingTimeFilter: Int, CaseIterable, Identifiable {
    case quick = 0      // 0-15 minutes
    case medium = 1     // 15-30 minutes
    case long = 2       // 30-60 minutes
    case extended = 3   // 60+ minutes
    
    var id: Int { rawValue }
    
    var displayText: String {
        switch self {
        case .quick:
            return "< 15 min"
        case .medium:
            return "15-30 min"
        case .long:
            return "30-60 min"
        case .extended:
            return "60+ min"
        }
    }
    
    var range: (min: Int, max: Int) {
        switch self {
        case .quick:
            return (0, 14)
        case .medium:
            return (15, 30)
        case .long:
            return (31, 60)
        case .extended:
            return (61, Int.max)
        }
    }
}

class SearchViewModel: ObservableObject {
    // MARK: - Properties
    
    private let firebaseService = FirebaseService.shared
    private var loadingTask: Task<Void, Never>?
    private var hasReachedEnd = false
    
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var selectedTimeFilter: CookingTimeFilter?
    @Published var selectedCuisine: String?
    
    let availableCuisines = [
        "Italian", "Chinese", "Japanese", "Mexican", "Indian",
        "Thai", "French", "American", "Mediterranean"
    ]
    
    var hasActiveFilters: Bool {
        selectedTimeFilter != nil || selectedCuisine != nil
    }
    
    init() {
        print("DEBUG: SearchViewModel initialized")
        // Load initial recipes when view model is created
        reloadRecipes()
    }
    
    // MARK: - Filter Methods
    
    func selectTimeFilter(_ filter: CookingTimeFilter) {
        print("DEBUG: Time filter selected - \(filter.displayText)")
        if selectedTimeFilter == filter {
            selectedTimeFilter = nil
            print("DEBUG: Time filter cleared")
        } else {
            selectedTimeFilter = filter
            print("DEBUG: Time filter set to \(filter.displayText)")
        }
        resetAndReload()
    }
    
    func selectCuisine(_ cuisine: String) {
        print("DEBUG: Cuisine filter selected - \(cuisine)")
        if selectedCuisine == cuisine {
            selectedCuisine = nil
            print("DEBUG: Cuisine filter cleared")
        } else {
            selectedCuisine = cuisine
            print("DEBUG: Cuisine filter set to \(cuisine)")
        }
        resetAndReload()
    }
    
    func clearFilters() {
        print("DEBUG: Clearing all filters")
        selectedTimeFilter = nil
        selectedCuisine = nil
        resetAndReload()
    }
    
    // MARK: - Data Loading
    
    private func resetAndReload() {
        recipes = []
        hasReachedEnd = false
        reloadRecipes()
    }
    
    private func reloadRecipes() {
        // Cancel any existing loading task
        loadingTask?.cancel()
        
        // Create a new loading task
        loadingTask = Task { @MainActor in
            // Add a small delay to debounce rapid filter changes
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check if the task was cancelled during the delay
            if Task.isCancelled { return }
            
            await loadRecipes()
        }
    }
    
    @MainActor
    private func loadRecipes() async {
        guard !isLoading else { return }
        
        print("DEBUG: Loading recipes with filters - Time: \(String(describing: selectedTimeFilter?.displayText)), Cuisine: \(String(describing: selectedCuisine))")
        isLoading = true
        do {
            let filteredRecipes = try await firebaseService.filterRecipes(
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            recipes = filteredRecipes
            hasReachedEnd = filteredRecipes.isEmpty
            print("DEBUG: Loaded \(recipes.count) recipes")
            if !recipes.isEmpty {
                print("DEBUG: Sample recipe - title: \(recipes[0].title), cuisine: \(recipes[0].cuisineType), time: \(recipes[0].cookingTime)")
            }
            error = nil
        } catch {
            self.error = error
            print("ERROR: Failed to load recipes - \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Pagination
    
    func loadMore() {
        guard !hasReachedEnd else {
            print("DEBUG: Reached end of list, no more recipes to load")
            return
        }
        
        Task {
            await loadMoreResults()
        }
    }
    
    @MainActor
    private func loadMoreResults() async {
        guard !isLoading && !hasReachedEnd,
              let lastRecipe = recipes.last else { return }
        
        isLoading = true
        do {
            let newRecipes = try await firebaseService.filterMoreRecipes(
                after: lastRecipe,
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            
            if newRecipes.isEmpty {
                hasReachedEnd = true
                print("DEBUG: No more recipes to load")
            } else {
                recipes.append(contentsOf: newRecipes)
                print("DEBUG: Loaded \(newRecipes.count) more recipes")
            }
            error = nil
        } catch {
            self.error = error
            print("Load more error: \(error)")
        }
        isLoading = false
    }
} 