import Foundation

@MainActor
class BookmarksViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var collections: [BookmarkCollection] = []
    @Published var selectedCollection: BookmarkCollection?
    @Published var recipesInCollection: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firebaseService: FirebaseService
    
    // MARK: - Initialization
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
    }
    
    // MARK: - Collection Operations
    
    func loadCollections() {
        Task {
            isLoading = true
            do {
                collections = try await firebaseService.fetchBookmarkCollections()
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func createCollection(name: String, description: String?) {
        Task {
            isLoading = true
            do {
                let collection = try await firebaseService.createBookmarkCollection(
                    name: name,
                    description: description
                )
                collections.insert(collection, at: 0)
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func deleteCollection(_ collectionId: String) {
        Task {
            isLoading = true
            do {
                try await firebaseService.deleteBookmarkCollection(collectionId)
                collections.removeAll { $0.id == collectionId }
                if selectedCollection?.id == collectionId {
                    selectedCollection = nil
                    recipesInCollection = []
                }
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func updateCollection(_ collection: BookmarkCollection) {
        Task {
            isLoading = true
            do {
                try await firebaseService.updateBookmarkCollection(collection)
                if let index = collections.firstIndex(where: { $0.id == collection.id }) {
                    collections[index] = collection
                }
                if selectedCollection?.id == collection.id {
                    selectedCollection = collection
                }
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    // MARK: - Recipe Operations
    
    func loadRecipesForCollection(_ collectionId: String) {
        Task {
            isLoading = true
            do {
                recipesInCollection = try await firebaseService.fetchRecipesForCollection(collectionId)
                error = nil
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func addRecipeToCollection(recipeId: String, collectionId: String) {
        Task {
            do {
                try await firebaseService.addRecipeToCollection(recipeId: recipeId, collectionId: collectionId)
                // Refresh collection if it's the selected one
                if selectedCollection?.id == collectionId {
                    loadRecipesForCollection(collectionId)
                }
                error = nil
            } catch {
                self.error = error
            }
        }
    }
    
    func removeRecipeFromCollection(recipeId: String, collectionId: String) {
        Task {
            do {
                try await firebaseService.removeRecipeFromCollection(recipeId: recipeId, collectionId: collectionId)
                // Update local state
                recipesInCollection.removeAll { $0.id == recipeId }
                error = nil
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Selection
    
    func selectCollection(_ collection: BookmarkCollection) {
        selectedCollection = collection
        loadRecipesForCollection(collection.id)
    }
    
    func clearSelection() {
        selectedCollection = nil
        recipesInCollection = []
    }
} 