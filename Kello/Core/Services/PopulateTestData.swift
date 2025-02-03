import Foundation
import FirebaseFirestore

class PopulateTestData {
    static let shared = PopulateTestData()
    private let firestore = FirebaseConfig.shared.firestore
    
    private init() {}
    
    // Simple function to populate test data
    static func populateTestData() {
        Task {
            do {
                print("🔄 Starting database population...")
                
                // First clear the database
                try await shared.clearDatabase()
                
                // Then populate with test data
                try await shared.populateDatabase()
                
                print("✅ Database population completed!")
            } catch {
                print("❌ Error populating database: \(error)")
            }
        }
    }
    
    func populateDatabase() async throws {
        // Sample cuisine types
        let cuisineTypes = ["Italian", "Japanese", "Mexican", "Indian", "Chinese", "American", "French", "Thai"]
        
        // Sample recipe data
        let recipes = [
            [
                "title": "Quick Spaghetti Carbonara",
                "description": "A classic Italian pasta dish made with eggs, cheese, pancetta, and black pepper.",
                "cookingTime": 20,
                "cuisineType": "Italian",
                "ingredients": [
                    "400g spaghetti",
                    "200g pancetta or guanciale",
                    "4 large eggs",
                    "100g Pecorino Romano",
                    "100g Parmigiano Reggiano",
                    "Black pepper",
                    "Salt"
                ],
                "steps": [
                    "Bring a large pot of salted water to boil",
                    "Cook spaghetti according to package instructions",
                    "Meanwhile, cook pancetta until crispy",
                    "Mix eggs, cheese, and pepper in a bowl",
                    "Combine pasta with egg mixture and pancetta",
                    "Serve immediately with extra cheese and pepper"
                ],
                "videoURL": "https://example.com/carbonara.mp4",
                "thumbnailURL": "https://example.com/carbonara-thumb.jpg",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0,
                "nutritionalInfo": [
                    "calories": 650,
                    "protein": 28.5,
                    "carbs": 72.0,
                    "fat": 25.8
                ]
            ],
            [
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
                "videoURL": "https://example.com/stirfry.mp4",
                "thumbnailURL": "https://example.com/stirfry-thumb.jpg",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0,
                "nutritionalInfo": [
                    "calories": 380,
                    "protein": 42.0,
                    "carbs": 18.5,
                    "fat": 15.2
                ]
            ],
            [
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
                "videoURL": "https://example.com/smoothie.mp4",
                "thumbnailURL": "https://example.com/smoothie-thumb.jpg",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0,
                "shares": 0,
                "nutritionalInfo": [
                    "calories": 285,
                    "protein": 15.5,
                    "carbs": 45.0,
                    "fat": 8.2
                ]
            ]
        ]
        
        // Add recipes to Firestore
        for recipe in recipes {
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