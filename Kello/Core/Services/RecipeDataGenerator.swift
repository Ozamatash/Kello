import Foundation
import FirebaseFirestore

/// A utility class to generate realistic recipe test data
class RecipeDataGenerator {
    // MARK: - Recipe Components
    
    private static let cuisineTypes = [
        "Italian", "Chinese", "Japanese", "Mexican", "Indian",
        "Thai", "French", "American", "Mediterranean", "Korean",
        "Vietnamese", "Spanish", "Greek", "Middle Eastern"
    ]
    
    private static let quickMeals = [
        ("5-Minute Microwave Oatmeal", 5, "Breakfast"),
        ("Quick Avocado Toast", 8, "Breakfast"),
        ("3-Minute Scrambled Eggs", 3, "Breakfast"),
        ("Instant Ramen Upgrade", 10, "Lunch"),
        ("Quick Tuna Sandwich", 7, "Lunch"),
        ("5-Minute Protein Smoothie", 5, "Breakfast"),
        ("Microwave Quesadilla", 6, "Snack"),
        ("2-Minute Mug Cake", 2, "Dessert")
    ]
    
    private static let mediumMeals = [
        ("Classic Pasta Carbonara", 25, "Dinner"),
        ("Chicken Stir Fry", 20, "Dinner"),
        ("Grilled Cheese & Tomato Soup", 15, "Lunch"),
        ("Buddha Bowl", 20, "Lunch"),
        ("Shrimp Tacos", 25, "Dinner"),
        ("Vegetable Curry", 30, "Dinner"),
        ("Greek Salad", 15, "Lunch"),
        ("Beef Burrito", 20, "Dinner")
    ]
    
    private static let longMeals = [
        ("Slow-Cooked Beef Stew", 180, "Dinner"),
        ("Homemade Pizza", 60, "Dinner"),
        ("Lasagna from Scratch", 90, "Dinner"),
        ("Sunday Roast Chicken", 75, "Dinner"),
        ("Authentic Pad Thai", 45, "Dinner"),
        ("Homemade Ramen", 120, "Dinner"),
        ("Beef Bourguignon", 180, "Dinner"),
        ("Biryani", 90, "Dinner")
    ]
    
    private static let commonIngredients = [
        // Proteins
        "chicken breast", "ground beef", "salmon fillet", "tofu", "eggs",
        // Vegetables
        "onion", "garlic", "carrots", "bell peppers", "broccoli",
        // Pantry
        "olive oil", "soy sauce", "rice", "pasta", "flour",
        // Dairy
        "butter", "milk", "cheese", "yogurt", "cream",
        // Herbs & Spices
        "salt", "black pepper", "cumin", "paprika", "oregano"
    ]
    
    private static func generateIngredients(count: Int) -> [String] {
        var ingredients = Set<String>()
        while ingredients.count < count {
            if let ingredient = commonIngredients.randomElement() {
                let quantity = ["1", "2", "3", "1/2", "1/4"].randomElement()!
                let unit = ["cup", "tablespoon", "teaspoon", "piece", "gram"].randomElement()!
                ingredients.insert("\(quantity) \(unit) \(ingredient)")
            }
        }
        return Array(ingredients)
    }
    
    private static func generateSteps(count: Int) -> [String] {
        let actionVerbs = ["Chop", "Mix", "Cook", "Stir", "Add", "Heat", "Combine", "Simmer", "Season", "Prepare"]
        let cookingTerms = ["until golden brown", "for 5 minutes", "until fragrant", "until well combined", "to taste"]
        
        var steps: [String] = []
        for i in 0..<count {
            let verb = actionVerbs.randomElement()!
            let term = cookingTerms.randomElement()!
            steps.append("\(i + 1). \(verb) ingredients \(term)")
        }
        return steps
    }
    
    private static func generateNutritionalInfo() -> (calories: Int, protein: Double, carbs: Double, fat: Double) {
        return (
            calories: Int.random(in: 200...800),
            protein: Double.random(in: 10...40),
            carbs: Double.random(in: 20...80),
            fat: Double.random(in: 5...30)
        )
    }
    
    // MARK: - Recipe Generation
    
    static func generateRecipe(videoURL: String, type: String = "random") -> [String: Any] {
        let meal: (title: String, time: Int, type: String)
        
        switch type {
        case "quick":
            meal = quickMeals.randomElement()!
        case "medium":
            meal = mediumMeals.randomElement()!
        case "long":
            meal = longMeals.randomElement()!
        default:
            meal = (quickMeals + mediumMeals + longMeals).randomElement()!
        }
        
        let nutrition = generateNutritionalInfo()
        let engagement = (
            likes: Int.random(in: 0...1000),
            comments: Int.random(in: 0...100),
            shares: Int.random(in: 0...50)
        )
        
        let ingredients = generateIngredients(count: Int.random(in: 5...12))
        let description = "A delicious \(meal.type.lowercased()) recipe that's perfect for any \(meal.type.lowercased()) occasion."
        
        // Create the ingredientsText that will be used for vector search
        let ingredientsText = "\(meal.title). \(description). Ingredients: \(ingredients.joined(separator: ", "))"
        
        return [
            "title": meal.title,
            "description": description,
            "cookingTime": meal.time,
            "cuisineType": cuisineTypes.randomElement()!,
            "mealType": meal.type,
            "ingredients": ingredients,
            "steps": generateSteps(count: Int.random(in: 4...8)),
            "videoURL": videoURL,
            "thumbnailURL": "https://example.com/\(meal.title.lowercased().replacingOccurrences(of: " ", with: "-")).jpg",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "likes": engagement.likes,
            "comments": engagement.comments,
            "shares": engagement.shares,
            "calories": nutrition.calories,
            "protein": nutrition.protein,
            "carbs": nutrition.carbs,
            "fat": nutrition.fat,
            "ingredientsText": ingredientsText,  // Add the text field for vector search
            "embedding": NSNull(),  // This will be populated by the Vector Search extension
            "embeddingStatus": NSNull()  // This will be populated by the Vector Search extension
        ]
    }
    
    static func generateBatch(count: Int, videoURLs: [String]) -> [[String: Any]] {
        var recipes: [[String: Any]] = []
        
        // Ensure we have a mix of quick, medium, and long recipes
        let quickCount = count / 3
        let mediumCount = count / 3
        let longCount = count - quickCount - mediumCount
        
        // Generate quick recipes
        for _ in 0..<quickCount {
            recipes.append(generateRecipe(
                videoURL: videoURLs[Int.random(in: 0..<videoURLs.count)],
                type: "quick"
            ))
        }
        
        // Generate medium recipes
        for _ in 0..<mediumCount {
            recipes.append(generateRecipe(
                videoURL: videoURLs[Int.random(in: 0..<videoURLs.count)],
                type: "medium"
            ))
        }
        
        // Generate long recipes
        for _ in 0..<longCount {
            recipes.append(generateRecipe(
                videoURL: videoURLs[Int.random(in: 0..<videoURLs.count)],
                type: "long"
            ))
        }
        
        return recipes.shuffled()
    }
} 