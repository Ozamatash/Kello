import Foundation
import FirebaseFirestore
import FirebaseStorage

class PopulateTestData {
    static let shared = PopulateTestData()
    private let firestore = FirebaseConfig.shared.firestore
    private let storage = FirebaseConfig.shared.storage
    
    private init() {}
    
    private func uploadTestVideos() async throws -> [String] {
        print("📂 Listing existing videos in Firebase Storage...")
        let storageRef = storage.reference().child("videos")
        
        // List all items in the videos folder
        let result = try await storageRef.listAll()
        
        guard !result.items.isEmpty else {
            throw NSError(domain: "PopulateTestData", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No videos found in Firebase Storage videos folder"
            ])
        }
        
        print("📁 Found \(result.items.count) videos in Firebase Storage")
        var downloadURLs: [String] = []
        
        // Get download URLs for all videos
        for item in result.items {
            do {
                print("🔗 Getting download URL for \(item.name)...")
                let downloadURL = try await item.downloadURL()
                downloadURLs.append(downloadURL.absoluteString)
                print("✅ Got download URL: \(downloadURL.absoluteString)")
            } catch {
                print("⚠️ Failed to get download URL for \(item.name): \(error)")
                // Continue with other videos even if one fails
                continue
            }
        }
        
        if downloadURLs.isEmpty {
            throw NSError(domain: "PopulateTestData", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No valid video URLs could be retrieved"
            ])
        }
        
        print("✅ Successfully retrieved \(downloadURLs.count) video URLs")
        return downloadURLs
    }
    
    // Simple function to populate test data
    static func populateTestData() {
        Task {
            do {
                print("🔄 Starting database population...")
                
                // First clear the database
                try await shared.clearDatabase()
                print("✅ Database cleared")
                
                // Upload test videos and get URLs
                print("📤 Starting video uploads...")
                let videoURLs = try await shared.uploadTestVideos()
                print("✅ Test videos uploaded successfully")
                
                // Then populate with test data
                print("📝 Populating database with recipes...")
                try await shared.populateDatabase(withVideoURLs: videoURLs)
                
                print("✅ Database population completed!")
            } catch {
                print("❌ Error populating database: \(error)")
                if let storageError = error as? StorageError {
                    print("📦 Storage Error Details: \(storageError)")
                }
                print("🔍 Full Error: \(String(describing: error))")
            }
        }
    }
    
    func populateDatabase(withVideoURLs videoURLs: [String]) async throws {
        print("🧑‍🍳 Generating recipes...")
        // Generate enough recipes to use all videos at least once
        // We want at least 60 recipes, but also enough to use each video at least once
        let minRecipeCount = max(60, videoURLs.count)
        // Generate recipes in batches of 3 (quick, medium, long) to ensure even distribution
        let batchSize = 3
        let numberOfBatches = (minRecipeCount + batchSize - 1) / batchSize
        let totalRecipes = numberOfBatches * batchSize
        
        print("📝 Will generate \(totalRecipes) recipes to ensure all \(videoURLs.count) videos are used...")
        let testRecipes = RecipeDataGenerator.generateBatch(count: totalRecipes, videoURLs: videoURLs)
        
        print("📝 Adding recipes to Firestore...")
        // Add recipes to Firestore
        for recipe in testRecipes {
            let docRef = try await firestore.collection("recipes").addDocument(data: recipe)
            
            // Generate 5-15 comments for each recipe
            print("💬 Generating comments for recipe \(docRef.documentID)...")
            let commentCount = Int.random(in: 5...15)
            let comments = MockUserGenerator.generateComments(for: docRef.documentID, count: commentCount)
            
            // Use batched writes for better performance
            let batch = firestore.batch()
            
            // Add comments and their likes in a single batch
            for comment in comments {
                let commentRef = firestore.collection("comments").document(comment.id)
                batch.setData(comment.toDictionary(), forDocument: commentRef)
                
                // Generate random likes for each comment
                let likeCount = Int.random(in: 0...5)
                let likers = Array(MockUserGenerator.mockUsers.shuffled().prefix(likeCount))
                
                // Add likes in the same batch
                for liker in likers {
                    let likeRef = commentRef.collection("likes").document(liker.id)
                    batch.setData([
                        "timestamp": Timestamp(date: Date().addingTimeInterval(-Double.random(in: 0...(86400))))
                    ], forDocument: likeRef)
                }
                
                // Update comment's like count in the same batch
                batch.updateData(["likes": likeCount], forDocument: commentRef)
            }
            
            // Update recipe with comment count in the same batch
            batch.updateData(["comments": commentCount], forDocument: docRef)
            
            // Commit all changes at once
            try await batch.commit()
        }
        
        print("✅ Test data successfully populated!")
    }
    
    func clearDatabase() async throws {
        print("🗑️ Starting database cleanup...")
        var batch = firestore.batch()
        var batchCount = 0
        let maxBatchSize = 500 // Firebase limit is 500 operations per batch
        
        // Function to commit batch and create a new one
        func commitBatchIfNeeded() async throws {
            if batchCount >= maxBatchSize {
                try await batch.commit()
                batch = firestore.batch() // Create a new batch
                batchCount = 0
            }
        }
        
        // 1. Clear recipes and their relationships
        print("🗑️ Clearing recipes...")
        let recipeSnapshot = try await firestore.collection("recipes").getDocuments()
        for document in recipeSnapshot.documents {
            batch.deleteDocument(document.reference)
            batchCount += 1
            try await commitBatchIfNeeded()
        }
        
        // 2. Clear comments and their likes
        print("🗑️ Clearing comments...")
        let commentSnapshot = try await firestore.collection("comments").getDocuments()
        for document in commentSnapshot.documents {
            batch.deleteDocument(document.reference)
            batchCount += 1
            try await commitBatchIfNeeded()
        }
        
        // 3. Clear bookmark collections
        print("🗑️ Clearing bookmark collections...")
        let collectionsSnapshot = try await firestore.collection("bookmarkCollections").getDocuments()
        for document in collectionsSnapshot.documents {
            batch.deleteDocument(document.reference)
            batchCount += 1
            try await commitBatchIfNeeded()
        }
        
        // 4. Clear user profiles and their relationships
        print("🗑️ Clearing user profiles...")
        let userProfilesSnapshot = try await firestore.collection("users").getDocuments()
        for document in userProfilesSnapshot.documents {
            // Reset user data instead of deleting the document
            // This preserves the user account but clears their data
            batch.updateData([
                "likedRecipes": [],
                "bookmarkedRecipes": [],
                "followingUsers": [],
                "followers": [],
                "recipeCount": 0
            ], forDocument: document.reference)
            batchCount += 1
            try await commitBatchIfNeeded()
        }
        
        // 5. Clear any pending likes
        print("🗑️ Clearing likes...")
        let likesSnapshot = try await firestore.collection("likes").getDocuments()
        for document in likesSnapshot.documents {
            batch.deleteDocument(document.reference)
            batchCount += 1
            try await commitBatchIfNeeded()
        }
        
        // Commit any remaining operations
        if batchCount > 0 {
            try await batch.commit()
        }
        
        print("✅ Database cleared successfully!")
    }
} 