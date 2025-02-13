import Foundation
import FirebaseFunctions
import FirebaseFirestore

/// Custom errors for recipe search
enum RecipeSearchError: LocalizedError {
    case invalidQuery
    case serverOverloaded
    case networkError
    case embeddingGenerationFailed
    case internalError
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "The search query is invalid. Please try with different terms."
        case .serverOverloaded:
            return "The search service is temporarily busy. Please try again."
        case .networkError:
            return "Network connection issue. Please check your connection."
        case .embeddingGenerationFailed:
            return "Unable to process search query. Please try again."
        case .internalError:
            return "An unexpected error occurred. Please try again."
        }
    }
}

class RecipeSearchService {
    private let functions = Functions.functions()
    private let firestore = Firestore.firestore()
    private let firebaseService = FirebaseService.shared
    
    // Retry configuration
    struct RetryConfig {
        let maxAttempts: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let backoffMultiplier: Double
        
        fileprivate static let `default` = RetryConfig(
            maxAttempts: 3,
            initialDelay: 0.5,
            maxDelay: 4.0,
            backoffMultiplier: 2.0
        )
    }
    
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
    
    /// Performs a semantic search for recipes with retry logic
    /// - Parameters:
    ///   - searchTerm: The ingredients or recipe description to search for
    /// - Returns: An array of recipe IDs sorted by relevance
    func searchRecipes(searchTerm: String) async throws -> [Recipe] {
        try await searchRecipes(searchTerm: searchTerm, retryConfig: .default)
    }
    
    /// Performs a semantic search for recipes with retry logic and custom configuration
    /// - Parameters:
    ///   - searchTerm: The ingredients or recipe description to search for
    ///   - retryConfig: Custom retry configuration
    /// - Returns: An array of recipe IDs sorted by relevance
    private func searchRecipes(
        searchTerm: String,
        retryConfig: RetryConfig
    ) async throws -> [Recipe] {
        guard !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecipeSearchError.invalidQuery
        }
        
        var attempt = 1
        var delay = retryConfig.initialDelay
        
        while attempt <= retryConfig.maxAttempts {
            do {
                return try await performSearch(searchTerm: searchTerm)
            } catch let error as NSError {
                let shouldRetry = shouldRetryError(error)
                let isLastAttempt = attempt == retryConfig.maxAttempts
                
                // Log the error for debugging
                print("🔍 Semantic search attempt \(attempt) failed: \(error.localizedDescription)")
                
                if shouldRetry && !isLastAttempt {
                    // Wait before retrying with exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay = min(delay * retryConfig.backoffMultiplier, retryConfig.maxDelay)
                    attempt += 1
                    continue
                }
                
                // Convert to appropriate RecipeSearchError
                throw mapToRecipeSearchError(error)
            }
        }
        
        throw RecipeSearchError.serverOverloaded
    }
    
    /// Internal method to perform the actual search
    private func performSearch(searchTerm: String) async throws -> [Recipe] {
        let queryRequest = QueryRequest(
            query: searchTerm,
            limit: 5,  // Limit to top 5 results
            prefilters: nil  // No filtering for now, but we could add cuisine type, cooking time filters later
        )
        
        let result = try await vectorSearchQueryCallable(queryRequest)
        print("Semantic search result IDs: \(result.ids)")
        
        // If we got results, fetch the full recipe documents
        if !result.ids.isEmpty {
            // Use FirebaseService to fetch recipes by IDs for consistent decoding
            return try await firebaseService.fetchRecipesByIds(result.ids)
        }
        
        return []
    }
    
    /// Determines if an error should trigger a retry
    private func shouldRetryError(_ error: NSError) -> Bool {
        // Firebase Functions error codes that should trigger retry
        let retryableCodes: Set<Int> = [
            4,    // Deadline exceeded
            8,    // Resource exhausted
            10,   // Aborted
            14,   // Unavailable
            -1001 // Network request failed
        ]
        
        return retryableCodes.contains(error.code)
    }
    
    /// Maps NSError to RecipeSearchError
    private func mapToRecipeSearchError(_ error: NSError) -> RecipeSearchError {
        switch error.code {
        case -1001, -1009: // Network request failed, No internet connection
            return .networkError
        case 8: // Resource exhausted
            return .serverOverloaded
        case 3: // Invalid argument
            return .invalidQuery
        case 13: // Internal error
            return .embeddingGenerationFailed
        default:
            return .internalError
        }
    }
} 