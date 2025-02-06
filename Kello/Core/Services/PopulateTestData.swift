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
        // Generate 30 recipes (10 of each type)
        let testRecipes = RecipeDataGenerator.generateBatch(count: 30, videoURLs: videoURLs)
        
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
        print("🗑️ Clearing recipes...")
        let recipeSnapshot = try await firestore.collection("recipes").getDocuments()
        for document in recipeSnapshot.documents {
            try await document.reference.delete()
        }
        
        print("🗑️ Clearing comments...")
        let commentSnapshot = try await firestore.collection("comments").getDocuments()
        for document in commentSnapshot.documents {
            // Delete all likes in the subcollection first
            let likesSnapshot = try await document.reference.collection("likes").getDocuments()
            for likeDoc in likesSnapshot.documents {
                try await likeDoc.reference.delete()
            }
            // Then delete the comment
            try await document.reference.delete()
        }
        
        print("✅ Database cleared successfully!")
    }
} 