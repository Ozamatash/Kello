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
                
                // Populate with real recipe data
                print("📝 Populating database with recipes...")
                try await shared.populateDatabase()
                
                print("✅ Database population completed!")
            } catch {
                print("❌ Error populating database: \(error)")
                print("🔍 Full Error: \(String(describing: error))")
            }
        }
    }
    
    class RecipeXMLParser: NSObject, XMLParserDelegate {
        private var currentElement = ""
        private var currentValue = ""
        
        var title = ""
        var ingredients: [String] = []
        var steps: [String] = []
        var categories: [String] = []
        var videoLowURL: String?
        var videoHighURL: String?
        private var isInVideo = false
        
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            currentElement = elementName
            currentValue = ""
            if elementName == "video" {
                isInVideo = true
            }
        }
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentValue += string
        }
        
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            let value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch elementName {
            case "title":
                title = value
            case "ingredient":
                let parts = value.components(separatedBy: ";")
                if parts.count > 1 {
                    ingredients.append(parts[1].trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    ingredients.append(parts[0].trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case "step":
                steps.append(value)
            case "category":
                categories.append(value)
            case "low" where isInVideo:
                videoLowURL = value
            case "high" where isInVideo:
                videoHighURL = value
            case "video":
                isInVideo = false
            default:
                break
            }
        }
    }
    
    private func parseRecipeXML(at path: String) throws -> [String: Any] {
        guard let xmlData = FileManager.default.contents(atPath: path) else {
            throw NSError(domain: "PopulateTestData", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Could not read XML file at \(path)"])
        }
        
        let parser = RecipeXMLParser()
        let xmlParser = XMLParser(data: xmlData)
        xmlParser.delegate = parser
        
        guard xmlParser.parse() else {
            throw NSError(domain: "PopulateTestData", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse XML"])
        }
        
        // Determine cuisine type
        let cuisineTypes = ["Italian", "Chinese", "Japanese", "Mexican", "Indian",
                           "Thai", "French", "American", "Mediterranean", "Korean",
                           "Vietnamese", "Spanish", "Greek", "Middle Eastern"]
        let cuisineType = parser.categories.first { cuisineTypes.contains($0) } ?? "Other"
        
        // Determine meal type
        let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]
        let mealType = parser.categories.first { mealTypes.contains($0) } ?? "Dinner"
        
        // Create recipe document
        return [
            "title": parser.title,
            "description": parser.steps.first ?? "",
            "cookingTime": parser.steps.count * 10, // Rough estimate based on number of steps
            "cuisineType": cuisineType,
            "mealType": mealType,
            "ingredients": parser.ingredients,
            "steps": parser.steps,
            "videoURL": parser.videoLowURL ?? parser.videoHighURL ?? "", // Prefer low-res (HLS) URL
            "thumbnailURL": "", // We'll need to generate these
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "likes": Int.random(in: 10...1000),
            "comments": 0,
            "shares": Int.random(in: 5...100)
        ]
    }
    
    func populateDatabase() async throws {
        // Get path to project root using environment variables
        let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] ?? ".."
        let recipesPath = "\(srcRoot)/recipes/ALL_RECIPES_without_videos"
        
        print("📂 Looking for recipes at: \(recipesPath)")
        
        let fileManager = FileManager.default
        let recipeDirectories = try fileManager.contentsOfDirectory(atPath: recipesPath)
            .filter { $0.first != "." } // Filter out hidden files
        
        print("📝 Found \(recipeDirectories.count) recipes, selecting 20 random ones...")
        let selectedRecipes = recipeDirectories.shuffled().prefix(20)  // Let's start with 20 for testing
        
        // Process each recipe
        for recipeName in selectedRecipes {
            let xmlPath = "\(recipesPath)/\(recipeName)/recipe.xml"
            
            do {
                print("📝 Processing recipe: \(recipeName)")
                let recipeData = try parseRecipeXML(at: xmlPath)
                
                // Add recipe to Firestore
                let docRef = try await firestore.collection("recipes").addDocument(data: recipeData)
                
                // Generate comments
                print("💬 Generating comments...")
                let commentCount = Int.random(in: 5...15)
                let comments = MockUserGenerator.generateComments(for: docRef.documentID, count: commentCount)
                
                // Use batched writes for comments
                let batch = firestore.batch()
                
                for comment in comments {
                    let commentRef = firestore.collection("comments").document(comment.id)
                    batch.setData(comment.toDictionary(), forDocument: commentRef)
                }
                
                // Update recipe with comment count
                batch.updateData(["comments": commentCount], forDocument: docRef)
                
                // Commit batch
                try await batch.commit()
                
                print("✅ Successfully added recipe: \(recipeName)")
            } catch {
                print("⚠️ Error processing recipe \(recipeName): \(error)")
                // Continue with other recipes
                continue
            }
        }
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