import Foundation
import FirebaseFirestore
import FirebaseStorage

class PopulateTestData {
    static let shared = PopulateTestData()
    private let firestore = FirebaseConfig.shared.firestore
    private let storage = FirebaseConfig.shared.storage
    
    private init() {}
    
    private func uploadTestVideos() async throws -> [String] {
        // More test videos from the public domain
        let testVideoURLs = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
        ]
        
        var downloadURLs: [String] = []
        
        for (index, videoURL) in testVideoURLs.enumerated() {
            do {
                let storageRef = storage.reference().child("videos/test-video-\(index + 1).mp4")
                print("📦 Created storage reference: \(storageRef)")
                
                print("🔗 Using test video URL: \(videoURL)")
                
                guard let url = URL(string: videoURL) else {
                    throw NSError(domain: "PopulateTestData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                }
                
                print("⬇️ Downloading video \(index + 1) data...")
                guard let videoData = try? Data(contentsOf: url) else {
                    throw NSError(domain: "PopulateTestData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to download video data"])
                }
                print("✅ Video data downloaded: \(ByteCountFormatter.string(fromByteCount: Int64(videoData.count), countStyle: .file))")
                
                print("⬆️ Starting upload to Firebase Storage...")
                let metadata = StorageMetadata()
                metadata.contentType = "video/mp4"
                _ = try await storageRef.putDataAsync(videoData, metadata: metadata)
                print("✅ Upload completed")
                
                print("🔗 Getting download URL...")
                let downloadURL = try await storageRef.downloadURL()
                print("✅ Got download URL: \(downloadURL.absoluteString)")
                
                downloadURLs.append(downloadURL.absoluteString)
            } catch {
                print("❌ Upload error for video \(index + 1): \(error)")
                throw error
            }
        }
        
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