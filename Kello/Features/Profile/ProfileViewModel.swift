import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userRecipes: [Recipe] = []
    @Published var likedRecipes: [Recipe] = []
    @Published var bookmarkCollections: [BookmarkCollection] = []
    @Published var error: String?
    @Published private(set) var isLoading = false
    
    private let firebaseService = FirebaseService.shared
    
    func loadUserData() async {
        isLoading = true
        error = nil
        
        do {
            // Load user's recipes
            let recipes = try await firebaseService.fetchUserRecipes()
            userRecipes = recipes
            
            // Load liked recipes
            let likedIds = try await firebaseService.fetchUserLikedRecipeIds()
            likedRecipes = try await loadRecipesInBatches(ids: likedIds)
            
            // Load bookmark collections
            bookmarkCollections = try await firebaseService.fetchBookmarkCollections()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadRecipesInBatches(ids: [String]) async throws -> [Recipe] {
        var recipes: [Recipe] = []
        let batchSize = 10
        
        for i in stride(from: 0, to: ids.count, by: batchSize) {
            let end = min(i + batchSize, ids.count)
            let batch = Array(ids[i..<end])
            let batchRecipes = try await firebaseService.fetchRecipesByIds(batch)
            recipes.append(contentsOf: batchRecipes)
        }
        
        return recipes
    }
} 