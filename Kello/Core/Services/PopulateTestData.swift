import Foundation
import FirebaseFirestore
import FirebaseStorage

class PopulateTestData {
    static let shared = PopulateTestData()
    private let firestore = FirebaseConfig.shared.firestore
    private let storage = FirebaseConfig.shared.storage
    
    private init() {}
    
    private func uploadTestVideos() async throws -> [String] {
        let testVideoURLs = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4", 
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4", 
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
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
        // Sample recipe data
        let testRecipes: [[String: Any]] = [
            [
                "id": UUID().uuidString,
                "title": "Classic Carbonara",
                "description": "A creamy Italian pasta dish with eggs and pancetta",
                "cookingTime": 25,
                "cuisineType": "Italian",
                "ingredients": ["Spaghetti", "Eggs", "Pancetta", "Parmesan", "Black Pepper"],
                "steps": ["Boil pasta", "Cook pancetta", "Mix eggs and cheese", "Combine all"],
                "videoURL": videoURLs[0],
                "thumbnailURL": "https://example.com/carbonara.jpg",
                "calories": 650,
                "protein": 25.0,
                "carbs": 70.0,
                "fat": 30.0,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0
            ],
            [
                "id": UUID().uuidString,
                "title": "15-Minute Chicken Stir Fry",
                "description": "A quick and healthy Asian-inspired stir fry with colorful vegetables.",
                "cookingTime": 15,
                "cuisineType": "Chinese",
                "ingredients": [
                    "500g chicken breast",
                    "2 bell peppers",
                    "1 broccoli head",
                    "2 carrots",
                    "4 tbsp soy sauce",
                    "2 tbsp sesame oil",
                    "Ginger and garlic"
                ],
                "steps": [
                    "Cut chicken into bite-sized pieces",
                    "Chop all vegetables",
                    "Heat oil in a wok",
                    "Stir-fry chicken until golden",
                    "Add vegetables and sauce",
                    "Cook until vegetables are crisp-tender"
                ],
                "videoURL": videoURLs[1],
                "thumbnailURL": "https://example.com/stirfry-thumb.jpg",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0,
                "calories": 380,
                "protein": 42.0,
                "carbs": 18.5,
                "fat": 15.2
            ],
            [
                "id": UUID().uuidString,
                "title": "5-Minute Breakfast Smoothie",
                "description": "A nutritious and quick breakfast smoothie packed with fruits and protein.",
                "cookingTime": 5,
                "cuisineType": "American",
                "ingredients": [
                    "1 banana",
                    "1 cup mixed berries",
                    "1 cup Greek yogurt",
                    "1 tbsp honey",
                    "1 cup almond milk",
                    "1 tbsp chia seeds"
                ],
                "steps": [
                    "Add all ingredients to blender",
                    "Blend until smooth",
                    "Pour into glass",
                    "Top with extra berries if desired"
                ],
                "videoURL": videoURLs[2],
                "thumbnailURL": "https://example.com/smoothie-thumb.jpg",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0,
                "calories": 285,
                "protein": 15.5,
                "carbs": 45.0,
                "fat": 8.2
            ]
        ]
        
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