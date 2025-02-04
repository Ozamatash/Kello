import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

class FirebaseService {
    static let shared = FirebaseService()
    private let config = FirebaseConfig.shared
    
    private init() {}
    
    // MARK: - Recipe Operations
    
    func fetchRecipes(limit: Int = 10) async throws -> [Recipe] {
        let snapshot = try await config.firestore
            .collection("recipes")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let recipe = Recipe(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                cookingTime: data["cookingTime"] as? Int ?? 0,
                cuisineType: data["cuisineType"] as? String ?? "",
                ingredients: data["ingredients"] as? [String] ?? [],
                steps: data["steps"] as? [String] ?? [],
                videoURL: data["videoURL"] as? String ?? "",
                thumbnailURL: data["thumbnailURL"] as? String ?? ""
            )
            
            // Set timestamps
            recipe.createdAt = createdAt
            recipe.updatedAt = updatedAt
            
            // Set engagement metrics
            recipe.likes = data["likes"] as? Int ?? 0
            recipe.comments = data["comments"] as? Int ?? 0
            recipe.shares = data["shares"] as? Int ?? 0
            
            // Set nutritional info
            if let nutritionalInfo = data["nutritionalInfo"] as? [String: Any] {
                recipe.calories = nutritionalInfo["calories"] as? Int
                recipe.protein = nutritionalInfo["protein"] as? Double
                recipe.carbs = nutritionalInfo["carbs"] as? Double
                recipe.fat = nutritionalInfo["fat"] as? Double
            }
            
            return recipe
        }
    }
    
    func fetchMoreRecipes(after lastRecipe: Recipe, limit: Int = 10) async throws -> [Recipe] {
        let snapshot = try await config.firestore
            .collection("recipes")
            .order(by: "createdAt", descending: true)
            .whereField("createdAt", isLessThan: lastRecipe.createdAt)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let recipe = Recipe(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                cookingTime: data["cookingTime"] as? Int ?? 0,
                cuisineType: data["cuisineType"] as? String ?? "",
                ingredients: data["ingredients"] as? [String] ?? [],
                steps: data["steps"] as? [String] ?? [],
                videoURL: data["videoURL"] as? String ?? "",
                thumbnailURL: data["thumbnailURL"] as? String ?? ""
            )
            
            // Set timestamps
            recipe.createdAt = createdAt
            recipe.updatedAt = updatedAt
            
            // Set engagement metrics
            recipe.likes = data["likes"] as? Int ?? 0
            recipe.comments = data["comments"] as? Int ?? 0
            recipe.shares = data["shares"] as? Int ?? 0
            
            // Set nutritional info
            if let nutritionalInfo = data["nutritionalInfo"] as? [String: Any] {
                recipe.calories = nutritionalInfo["calories"] as? Int
                recipe.protein = nutritionalInfo["protein"] as? Double
                recipe.carbs = nutritionalInfo["carbs"] as? Double
                recipe.fat = nutritionalInfo["fat"] as? Double
            }
            
            return recipe
        }
    }
    
    // MARK: - Video Operations
    
    func uploadVideo(videoURL: URL) async throws -> String {
        let filename = UUID().uuidString + ".mp4"
        let storageRef = config.storage.reference().child("videos/\(filename)")
        
        _ = try await storageRef.putFileAsync(from: videoURL)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - User Engagement
    
    func likeRecipe(_ recipeId: String) async throws {
        try await config.firestore
            .collection("recipes")
            .document(recipeId)
            .updateData([
                "likes": FieldValue.increment(Int64(1))
            ])
    }
    
    func addComment(to recipeId: String, comment: String) async throws {
        try await config.firestore
            .collection("recipes")
            .document(recipeId)
            .collection("comments")
            .addDocument(data: [
                "text": comment,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Filtering
    
    func filterRecipes(
        timeFilter: CookingTimeFilter? = nil,
        cuisine: String? = nil,
        mealType: String? = nil,
        limit: Int = 20
    ) async throws -> [Recipe] {
        var query: Query = config.firestore.collection("recipes")
        
        // Apply equality filters first (most selective)
        if let cuisine = cuisine {
            query = query.whereField("cuisineType", isEqualTo: cuisine)
        }
        
        if let mealType = mealType {
            query = query.whereField("mealType", isEqualTo: mealType)
        }
        
        // Apply range filter and corresponding order
        if let timeFilter = timeFilter {
            let range = timeFilter.range
            query = query.order(by: "cookingTime")
            
            if timeFilter == .extended {
                query = query.whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
            } else {
                query = query
                    .whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
                    .whereField("cookingTime", isLessThan: range.max)
            }
            
            // After range filter, add secondary ordering
            query = query.order(by: "createdAt", descending: true)
        } else {
            // If no time filter, just order by creation date
            query = query.order(by: "createdAt", descending: true)
        }
        
        // Get documents
        let snapshot = try await query
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            return try decodeRecipe(from: data, withId: document.documentID)
        }
    }
    
    func filterMoreRecipes(
        after lastRecipe: Recipe,
        timeFilter: CookingTimeFilter? = nil,
        cuisine: String? = nil,
        mealType: String? = nil,
        limit: Int = 20
    ) async throws -> [Recipe] {
        var query: Query = config.firestore.collection("recipes")
        
        // Apply equality filters first (most selective)
        if let cuisine = cuisine {
            query = query.whereField("cuisineType", isEqualTo: cuisine)
        }
        
        if let mealType = mealType {
            query = query.whereField("mealType", isEqualTo: mealType)
        }
        
        // Apply range filter and corresponding order
        if let timeFilter = timeFilter {
            let range = timeFilter.range
            query = query.order(by: "cookingTime")
            
            if timeFilter == .extended {
                query = query.whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
            } else {
                query = query
                    .whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
                    .whereField("cookingTime", isLessThan: range.max)
            }
            
            // After range filter, add secondary ordering and cursor
            query = query
                .order(by: "createdAt", descending: true)
                .whereField("createdAt", isLessThan: lastRecipe.createdAt)
        } else {
            // If no time filter, just order by creation date and add cursor
            query = query
                .order(by: "createdAt", descending: true)
                .whereField("createdAt", isLessThan: lastRecipe.createdAt)
        }
        
        // Get documents
        let snapshot = try await query
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            return try decodeRecipe(from: data, withId: document.documentID)
        }
    }
    
    // MARK: - Search Operations
    
    func searchRecipes(
        query searchQuery: String,
        timeFilter: CookingTimeFilter? = nil,
        cuisine: String? = nil,
        mealType: String? = nil,
        limit: Int = 20
    ) async throws -> [Recipe] {
        var query: Query = config.firestore.collection("recipes")
        
        // Apply equality filters first (most selective)
        if let cuisine = cuisine {
            query = query.whereField("cuisineType", isEqualTo: cuisine)
        }
        
        if let mealType = mealType {
            query = query.whereField("mealType", isEqualTo: mealType)
        }
        
        // Apply text search if query is not empty
        // Note: This requires a composite index on title and other filtered fields
        if !searchQuery.isEmpty {
            query = query
                .order(by: "title")
                .whereField("title", isGreaterThanOrEqualTo: searchQuery)
                .whereField("title", isLessThanOrEqualTo: searchQuery + "\u{f8ff}")
        }
        
        // Apply range filter and corresponding order
        if let timeFilter = timeFilter {
            let range = timeFilter.range
            query = query.order(by: "cookingTime")
            
            if timeFilter == .extended {
                query = query.whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
            } else {
                query = query
                    .whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
                    .whereField("cookingTime", isLessThan: range.max)
            }
            
            // After range filter, add final ordering
            query = query.order(by: "createdAt", descending: true)
        } else if searchQuery.isEmpty {
            // If no time filter and no search query, order by creation date
            query = query.order(by: "createdAt", descending: true)
        }
        
        // Get documents
        let snapshot = try await query
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            return try decodeRecipe(from: data, withId: document.documentID)
        }
    }
    
    func searchMoreRecipes(
        after lastRecipe: Recipe,
        timeFilter: CookingTimeFilter? = nil,
        cuisine: String? = nil,
        limit: Int = 20
    ) async throws -> [Recipe] {
        // Start with the base collection reference
        let baseQuery = config.firestore.collection("recipes")
        
        // Build the query starting with the order
        var finalQuery: Query = baseQuery.order(by: "createdAt", descending: true)
        
        // Add the cursor
        finalQuery = finalQuery.whereField("createdAt", isLessThan: lastRecipe.createdAt)
        
        // Apply time filter first (if any)
        if let timeFilter = timeFilter {
            let range = timeFilter.range
            // For extended time, we only need the lower bound
            if timeFilter == .extended {
                finalQuery = finalQuery.whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
            } else {
                finalQuery = finalQuery
                    .whereField("cookingTime", isGreaterThanOrEqualTo: range.min)
                    .whereField("cookingTime", isLessThan: range.max)
            }
        }
        
        // Apply cuisine filter
        if let cuisine = cuisine {
            finalQuery = finalQuery.whereField("cuisineType", isEqualTo: cuisine)
        }
        
        // Get documents
        let snapshot = try await finalQuery
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            return try decodeRecipe(from: data, withId: document.documentID)
        }
    }
    
    // Helper method to decode recipe from Firestore data
    private func decodeRecipe(from data: [String: Any], withId id: String) throws -> Recipe {
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        let recipe = Recipe(
            id: id,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            cookingTime: data["cookingTime"] as? Int ?? 0,
            cuisineType: data["cuisineType"] as? String ?? "",
            ingredients: data["ingredients"] as? [String] ?? [],
            steps: data["steps"] as? [String] ?? [],
            videoURL: data["videoURL"] as? String ?? "",
            thumbnailURL: data["thumbnailURL"] as? String ?? ""
        )
        
        // Set timestamps
        recipe.createdAt = createdAt
        recipe.updatedAt = updatedAt
        
        // Set engagement metrics
        recipe.likes = data["likes"] as? Int ?? 0
        recipe.comments = data["comments"] as? Int ?? 0
        recipe.shares = data["shares"] as? Int ?? 0
        
        // Set nutritional info
        if let nutritionalInfo = data["nutritionalInfo"] as? [String: Any] {
            recipe.calories = nutritionalInfo["calories"] as? Int
            recipe.protein = nutritionalInfo["protein"] as? Double
            recipe.carbs = nutritionalInfo["carbs"] as? Double
            recipe.fat = nutritionalInfo["fat"] as? Double
        }
        
        return recipe
    }
} 