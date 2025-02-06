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
        // Generate 30 recipes (10 of each type)
        let testRecipes = RecipeDataGenerator.generateBatch(count: 30, videoURLs: videoURLs)
        
        // Add recipes to Firestore
        for recipe in testRecipes {
            try await firestore.collection("recipes").addDocument(data: recipe)
        }
        
        print("✅ Test data successfully populated!")
    }
    
    func clearDatabase() async throws {
        let snapshot = try await firestore.collection("recipes").getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        print("✅ Database cleared successfully!")
    }
} 