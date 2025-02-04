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
    private var searchTask: Task<Void, Never>?
    @Published var currentQuery = ""
    
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var selectedTimeFilter: CookingTimeFilter?
    @Published var selectedCuisine: String?
    
    let availableCuisines = [
        "Italian", "Chinese", "Japanese", "Mexican", "Indian",
        "Thai", "French", "American", "Mediterranean"
    ]
    
    // MARK: - Search Methods
    
    func search(query: String) {
        currentQuery = query
        executeSearch()
    }
    
    private func executeSearch() {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task with debounce
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            
            guard !Task.isCancelled else { return }
            
            await performSearch(query: currentQuery)
        }
    }
    
    @MainActor
    private func performSearch(query: String) async {
        isLoading = true
        do {
            recipes = try await firebaseService.searchRecipes(
                query: query,
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            error = nil
        } catch {
            self.error = error
            print("Search error: \(error)")
        }
        isLoading = false
    }
    
    func clearSearch() {
        currentQuery = ""
        recipes = []
        error = nil
        selectedTimeFilter = nil
        selectedCuisine = nil
    }
    
    // MARK: - Filter Methods
    
    func selectTimeFilter(_ filter: CookingTimeFilter) {
        if selectedTimeFilter == filter {
            selectedTimeFilter = nil
        } else {
            selectedTimeFilter = filter
        }
        executeSearch()
    }
    
    func selectCuisine(_ cuisine: String) {
        if selectedCuisine == cuisine {
            selectedCuisine = nil
        } else {
            selectedCuisine = cuisine
        }
        executeSearch()
    }
    
    // MARK: - Pagination
    
    func loadMore() {
        Task {
            await loadMoreResults()
        }
    }
    
    @MainActor
    private func loadMoreResults() async {
        guard !isLoading,
              let lastRecipe = recipes.last else { return }
        
        isLoading = true
        do {
            let newRecipes = try await firebaseService.searchMoreRecipes(
                after: lastRecipe,
                timeFilter: selectedTimeFilter,
                cuisine: selectedCuisine
            )
            recipes.append(contentsOf: newRecipes)
            error = nil
        } catch {
            self.error = error
            print("Load more error: \(error)")
        }
        isLoading = false
    }
} 