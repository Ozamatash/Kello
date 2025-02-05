import Foundation
import FirebaseFunctions
import FirebaseFirestore

class RecipeSearchService {
    private let functions = Functions.functions()
    private let firestore = Firestore.firestore()
    
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
                let snapshot = try await firestore.collection("recipes")
                    .whereField("id", in: result.ids)
                    .getDocuments()
                
                // Convert Firestore documents to Recipe objects
                return snapshot.documents.compactMap { document in
                    guard let data = document.data() as? [String: Any],
                          let id = data["id"] as? String,
                          let title = data["title"] as? String,
                          let description = data["description"] as? String,
                          let cookingTime = data["cookingTime"] as? Int,
                          let cuisineType = data["cuisineType"] as? String,
                          let ingredients = data["ingredients"] as? [String],
                          let steps = data["steps"] as? [String],
                          let videoURL = data["videoURL"] as? String,
                          let thumbnailURL = data["thumbnailURL"] as? String else {
                        return nil
                    }
                    
                    return Recipe(
                        id: id,
                        title: title,
                        description: description,
                        cookingTime: cookingTime,
                        cuisineType: cuisineType,
                        ingredients: ingredients,
                        steps: steps,
                        videoURL: videoURL,
                        thumbnailURL: thumbnailURL
                    )
                }
            }
            
            return []
        } catch {
            print("🔍 Semantic search failed: \(error.localizedDescription)")
            throw error
        }
    }
} 