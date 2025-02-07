import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import AVFoundation

enum AuthError: LocalizedError {
    case userNotFound
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please sign in first."
        case .invalidEmail:
            return "The email address is badly formatted."
        case .weakPassword:
            return "The password must be at least 6 characters long."
        case .emailAlreadyInUse:
            return "The email address is already in use."
        case .wrongPassword:
            return "The password is incorrect."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

class FirebaseService {
    static let shared = FirebaseService()
    private let config = FirebaseConfig.shared
    
    private init() {}
    
    // MARK: - Recipe Operations
    
    func fetchRecipesByIds(_ ids: [String]) async throws -> [Recipe] {
        let snapshot = try await config.firestore
            .collection("recipes")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments()
        
        return try await decodeRecipes(from: snapshot.documents)
    }
    
    func fetchRecipes(limit: Int = 10) async throws -> [Recipe] {
        let snapshot = try await config.firestore
            .collection("recipes")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let recipe = Recipe(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                cookingTime: data["cookingTime"] as? Int ?? 0,
                cuisineType: data["cuisineType"] as? String ?? "",
                mealType: data["mealType"] as? String ?? "Dinner",
                ingredients: data["ingredients"] as? [String] ?? [],
                steps: data["steps"] as? [String] ?? [],
                videoURL: data["videoURL"] as? String ?? "",
                thumbnailURL: data["thumbnailURL"] as? String ?? "",
                calories: data["calories"] as? Int,
                protein: data["protein"] as? Double,
                carbs: data["carbs"] as? Double,
                fat: data["fat"] as? Double,
                embedding: data["embedding"] as? [Double],
                embeddingStatus: data["embeddingStatus"] as? String
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
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            let recipe = Recipe(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                cookingTime: data["cookingTime"] as? Int ?? 0,
                cuisineType: data["cuisineType"] as? String ?? "",
                mealType: data["mealType"] as? String ?? "Dinner",
                ingredients: data["ingredients"] as? [String] ?? [],
                steps: data["steps"] as? [String] ?? [],
                videoURL: data["videoURL"] as? String ?? "",
                thumbnailURL: data["thumbnailURL"] as? String ?? "",
                calories: data["calories"] as? Int,
                protein: data["protein"] as? Double,
                carbs: data["carbs"] as? Double,
                fat: data["fat"] as? Double,
                embedding: data["embedding"] as? [Double],
                embeddingStatus: data["embeddingStatus"] as? String
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
    
    // MARK: - Recipe Creation
    
    func createRecipe(
        title: String,
        description: String,
        cookingTime: Int,
        cuisineType: String,
        mealType: String,
        ingredients: [String],
        steps: [String],
        videoURL: URL
    ) async throws -> Recipe {
        guard let userId = config.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // 1. Upload video
        let videoDownloadURL = try await uploadVideo(videoURL: videoURL)
        
        // 2. Generate and upload thumbnail
        let thumbnailURL = try await generateAndUploadThumbnail(from: videoURL)
        
        // 3. Create recipe document
        let recipeData: [String: Any] = [
            "title": title,
            "description": description,
            "cookingTime": cookingTime,
            "cuisineType": cuisineType,
            "mealType": mealType,
            "ingredients": ingredients,
            "steps": steps,
            "videoURL": videoDownloadURL,
            "thumbnailURL": thumbnailURL,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "likes": 0,
            "comments": 0,
            "shares": 0
        ]
        
        let docRef = try await config.firestore
            .collection("recipes")
            .addDocument(data: recipeData)
        
        // 4. Return the created recipe
        return Recipe(
            id: docRef.documentID,
            title: title,
            description: description,
            cookingTime: cookingTime,
            cuisineType: cuisineType,
            mealType: mealType,
            ingredients: ingredients,
            steps: steps,
            videoURL: videoDownloadURL,
            thumbnailURL: thumbnailURL
        )
    }
    
    // MARK: - Video Operations
    
    private func generateAndUploadThumbnail(from videoURL: URL) async throws -> String {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Get the first frame
        let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert to Data
        guard let imageData = uiImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"])
        }
        
        // Upload to Firebase Storage
        let filename = UUID().uuidString + ".jpg"
        let storageRef = config.storage.reference().child("thumbnails/\(filename)")
        
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func uploadVideo(videoURL: URL) async throws -> String {
        // Validate video size
        let resources = try videoURL.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = resources.fileSize else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine video size"])
        }
        
        // Maximum size: 100MB
        let maxSize = 100 * 1024 * 1024
        guard fileSize <= maxSize else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video size must be less than 100MB"])
        }
        
        // Upload to Firebase Storage
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
    
    func unlikeRecipe(_ recipeId: String) async throws {
        try await config.firestore
            .collection("recipes")
            .document(recipeId)
            .updateData([
                "likes": FieldValue.increment(Int64(-1))
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
    
    // MARK: - Bookmark Collections
    
    func createBookmarkCollection(name: String, description: String? = nil) async throws -> BookmarkCollection {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let collection = BookmarkCollection(
            userId: userId,
            name: name,
            description: description
        )
        
        let docRef = try await config.firestore
            .collection("bookmarkCollections")
            .addDocument(data: collection.toDictionary())
        
        return BookmarkCollection(
            id: docRef.documentID,
            userId: collection.userId,
            name: collection.name,
            description: collection.description,
            recipeIds: [],
            thumbnailURL: nil
        )
    }
    
    func deleteBookmarkCollection(_ collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        // Verify ownership before deleting
        let doc = try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .getDocument()
        
        guard let data = doc.data(),
              let collectionUserId = data["userId"] as? String,
              collectionUserId == userId else {
            throw AuthError.userNotFound
        }
        
        try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .delete()
    }
    
    func updateBookmarkCollection(_ collection: BookmarkCollection) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              userId == collection.userId else {
            throw AuthError.userNotFound
        }
        
        try await config.firestore
            .collection("bookmarkCollections")
            .document(collection.id)
            .updateData([
                "name": collection.name,
                "description": collection.description as Any,
                "updatedAt": Timestamp(date: Date()),
                "thumbnailURL": collection.thumbnailURL as Any
            ])
    }
    
    func addRecipeToCollection(recipeId: String, collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        // Verify collection ownership
        let doc = try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .getDocument()
        
        guard let data = doc.data(),
              let collectionUserId = data["userId"] as? String,
              collectionUserId == userId else {
            throw AuthError.userNotFound
        }
        
        // Get recipe thumbnail for first recipe
        let recipeIds = (data["recipeIds"] as? [String]) ?? []
        if recipeIds.isEmpty {
            let recipe = try await config.firestore
                .collection("recipes")
                .document(recipeId)
                .getDocument()
            
            if let recipeData = recipe.data(),
               let thumbnailURL = recipeData["thumbnailURL"] as? String {
                try await config.firestore
                    .collection("bookmarkCollections")
                    .document(collectionId)
                    .updateData([
                        "recipeIds": FieldValue.arrayUnion([recipeId]),
                        "thumbnailURL": thumbnailURL,
                        "updatedAt": Timestamp(date: Date())
                    ])
                return
            }
        }
        
        // If not first recipe or thumbnail not found, just add the recipe
        try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .updateData([
                "recipeIds": FieldValue.arrayUnion([recipeId]),
                "updatedAt": Timestamp(date: Date())
            ])
    }
    
    func removeRecipeFromCollection(recipeId: String, collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        // Verify collection ownership
        let doc = try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .getDocument()
        
        guard let data = doc.data(),
              let collectionUserId = data["userId"] as? String,
              collectionUserId == userId else {
            throw AuthError.userNotFound
        }
        
        try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .updateData([
                "recipeIds": FieldValue.arrayRemove([recipeId]),
                "updatedAt": Timestamp(date: Date())
            ])
        
        // If this was the first recipe (thumbnail), update thumbnail to next recipe if available
        if let _ = data["thumbnailURL"] as? String,
           let recipeIds = data["recipeIds"] as? [String],
           recipeIds.first == recipeId,
           let nextRecipeId = recipeIds.dropFirst().first {
            let nextRecipe = try await config.firestore
                .collection("recipes")
                .document(nextRecipeId)
                .getDocument()
            
            if let recipeData = nextRecipe.data(),
               let newThumbnailURL = recipeData["thumbnailURL"] as? String {
                try await config.firestore
                    .collection("bookmarkCollections")
                    .document(collectionId)
                    .updateData([
                        "thumbnailURL": newThumbnailURL
                    ])
            }
        }
    }
    
    func fetchBookmarkCollections() async throws -> [BookmarkCollection] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let snapshot = try await config.firestore
            .collection("bookmarkCollections")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { BookmarkCollection(from: $0) }
    }
    
    func fetchRecipesForCollection(_ collectionId: String) async throws -> [Recipe] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        // Get collection and verify ownership
        let doc = try await config.firestore
            .collection("bookmarkCollections")
            .document(collectionId)
            .getDocument()
        
        guard let data = doc.data(),
              let collectionUserId = data["userId"] as? String,
              collectionUserId == userId,
              let recipeIds = data["recipeIds"] as? [String] else {
            throw AuthError.userNotFound
        }
        
        // If no recipes, return empty array
        if recipeIds.isEmpty {
            return []
        }
        
        // Fetch recipes in batches to avoid Firestore limits
        var recipes: [Recipe] = []
        let batchSize = 10
        for i in stride(from: 0, to: recipeIds.count, by: batchSize) {
            let end = min(i + batchSize, recipeIds.count)
            let batch = Array(recipeIds[i..<end])
            let batchRecipes = try await fetchRecipesByIds(batch)
            recipes.append(contentsOf: batchRecipes)
        }
        
        return recipes
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
        
        return try await decodeRecipes(from: snapshot.documents)
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
        
        return try await decodeRecipes(from: snapshot.documents)
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
        }
        
        // Get documents
        let snapshot = try await query
            .limit(to: limit)
            .getDocuments()
        
        return try await decodeRecipes(from: snapshot.documents)
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
        
        return try await decodeRecipes(from: snapshot.documents)
    }
    
    // MARK: - Helper Methods
    
    private func decodeRecipes(from documents: [QueryDocumentSnapshot]) async throws -> [Recipe] {
        return documents.compactMap { document in
            let data = document.data()
            return decodeRecipe(from: data, withId: document.documentID)
        }
    }
    
    private func decodeRecipe(from data: [String: Any], withId id: String) -> Recipe {
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        let recipe = Recipe(
            id: id,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            cookingTime: data["cookingTime"] as? Int ?? 0,
            cuisineType: data["cuisineType"] as? String ?? "",
            mealType: data["mealType"] as? String ?? "Dinner",
            ingredients: data["ingredients"] as? [String] ?? [],
            steps: data["steps"] as? [String] ?? [],
            videoURL: data["videoURL"] as? String ?? "",
            thumbnailURL: data["thumbnailURL"] as? String ?? "",
            calories: data["calories"] as? Int,
            protein: data["protein"] as? Double,
            carbs: data["carbs"] as? Double,
            fat: data["fat"] as? Double,
            embedding: data["embedding"] as? [Double],
            embeddingStatus: data["embeddingStatus"] as? String,
            isLikedByCurrentUser: false // Default to false, will be updated when checking likes
        )
        
        // Set timestamps
        recipe.createdAt = createdAt
        recipe.updatedAt = updatedAt
        
        // Set engagement metrics
        recipe.likes = data["likes"] as? Int ?? 0
        recipe.comments = data["comments"] as? Int ?? 0
        recipe.shares = data["shares"] as? Int ?? 0
        
        // Check if the current user has liked this recipe
        if let currentUser = config.auth.currentUser,
           let likedBy = data["likedBy"] as? [String],
           likedBy.contains(currentUser.uid) {
            recipe.isLikedByCurrentUser = true
        }
        
        return recipe
    }
    
    // Comments
    func fetchComments(for recipeId: String) async throws -> [Comment] {
        let commentsRef = config.firestore.collection("comments")
            .whereField("recipeId", isEqualTo: recipeId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
        
        let snapshot = try await commentsRef.getDocuments()
        return snapshot.documents.compactMap { Comment(from: $0) }
    }
    
    func addComment(to recipeId: String, text: String) async throws -> Comment {
        guard let currentUser = config.auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let commentsRef = config.firestore.collection("comments")
        let comment = Comment(
            userId: currentUser.uid,
            recipeId: recipeId,
            text: text,
            userDisplayName: currentUser.displayName ?? "Anonymous"
        )
        
        try await commentsRef.document(comment.id).setData(comment.toDictionary())
        return comment
    }
    
    func likeComment(_ commentId: String) async throws {
        guard let currentUser = config.auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let commentRef = config.firestore.collection("comments").document(commentId)
        let likeRef = commentRef.collection("likes").document(currentUser.uid)
        
        _ = try await config.firestore.runTransaction { transaction, _ -> Any? in
            let commentDoc: DocumentSnapshot
            do {
                commentDoc = try transaction.getDocument(commentRef)
            } catch {
                return nil
            }
            
            guard var likes = commentDoc.data()?["likes"] as? Int else { return nil }
            
            likes += 1
            transaction.updateData(["likes": likes], forDocument: commentRef)
            transaction.setData(["userId": currentUser.uid], forDocument: likeRef)
            
            return nil
        }
    }
    
    func unlikeComment(_ commentId: String) async throws {
        guard let currentUser = config.auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let commentRef = config.firestore.collection("comments").document(commentId)
        let likeRef = commentRef.collection("likes").document(currentUser.uid)
        
        _ = try await config.firestore.runTransaction { transaction, _ -> Any? in
            let commentDoc: DocumentSnapshot
            do {
                commentDoc = try transaction.getDocument(commentRef)
            } catch {
                return nil
            }
            
            guard var likes = commentDoc.data()?["likes"] as? Int else { return nil }
            
            likes = max(0, likes - 1)
            transaction.updateData(["likes": likes], forDocument: commentRef)
            transaction.deleteDocument(likeRef)
            
            return nil
        }
    }
    
    // MARK: - User Recipe Operations
    
    func fetchUserRecipes() async throws -> [Recipe] {
        guard let userId = config.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await config.firestore
            .collection("recipes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await decodeRecipes(from: snapshot.documents)
    }
    
    func fetchUserLikedRecipeIds() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.userNotFound
        }
        
        let doc = try await config.firestore
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard let data = doc.data() else {
            return []
        }
        
        return (data["likedRecipes"] as? [String]) ?? []
    }
} 