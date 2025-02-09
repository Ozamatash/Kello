import Foundation
import FirebaseFunctions
import FirebaseFirestore

class RecipeSearchService {
    private let functions = Functions.functions()
    private let firestore = Firestore.firestore()
    private let firebaseService = FirebaseService.shared
    
    // Set up the callable function for semantic search
    private lazy var vectorSearchQueryCallable: Callable<QueryRequest, QueryResponse> = {
        functions.httpsCallable("ext-firestore-vector-search-queryCallable")
    }()
    
    /// Query input structure for the semantic search
    private struct QueryRequest: Codable {
        var query: String
        var limit: Int?
        var prefilters: [QueryFilter]?
    }

    /// Used to optionally filter the documents
    private struct QueryFilter: Codable {
        var field: String
        var `operator`: String
        var value: String
    }

    /// Expected response structure from the Cloud Function
    private struct QueryResponse: Codable {
        var ids: [String]
    }
    
    /// Performs a semantic search for recipes based on the provided ingredients or search term
    /// - Parameter searchTerm: The ingredients or recipe description to search for
    /// - Returns: An array of recipe IDs sorted by relevance
    func searchRecipes(searchTerm: String) async throws -> [Recipe] {
        let queryRequest = QueryRequest(
            query: searchTerm,
            limit: 5,  // Limit to top 5 results
            prefilters: nil  // No filtering for now, but we could add cuisine type, cooking time filters later
        )
        
        do {
            // Call the vector search function
            let result = try await vectorSearchQueryCallable(queryRequest)
            print("Semantic search result IDs: \(result.ids)")
            
            // If we got results, fetch the full recipe documents
            if !result.ids.isEmpty {
                // Use FirebaseService to fetch recipes by IDs for consistent decoding
                return try await firebaseService.fetchRecipesByIds(result.ids)
            }
            
            return []
        } catch {
            print("🔍 Semantic search failed: \(error.localizedDescription)")
            throw error
        }
    }
} 