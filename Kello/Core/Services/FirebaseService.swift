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
    
    func fetchRecipes(
        cuisineType: String? = nil,
        maxCookingTime: Int? = nil,
        limit: Int = 10
    ) async throws -> [Recipe] {
        var query = config.firestore
            .collection("recipes")
            .order(by: "createdAt", descending: true)
        
        if let cuisineType = cuisineType {
            query = query.whereField("cuisineType", isEqualTo: cuisineType)
        }
        
        if let maxCookingTime = maxCookingTime {
            query = query.whereField("cookingTime", isLessThanOrEqualTo: maxCookingTime)
        }
        
        let snapshot = try await query.limit(to: limit).getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            
            return Recipe(
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
        }
    }
} 