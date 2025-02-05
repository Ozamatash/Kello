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
        ("chicken breast", "lean, boneless"),
        ("ground beef", "lean, grass-fed"),
        ("salmon fillet", "fresh, skin-on"),
        ("tofu", "firm, extra firm"),
        ("eggs", "large, free-range"),
        // Vegetables
        ("onion", "yellow, finely diced"),
        ("garlic", "fresh, minced"),
        ("carrots", "fresh, julienned"),
        ("bell peppers", "red, thinly sliced"),
        ("broccoli", "fresh, cut into florets"),
        // Pantry
        ("olive oil", "extra virgin"),
        ("soy sauce", "low-sodium"),
        ("rice", "jasmine, long-grain"),
        ("pasta", "dried, whole wheat"),
        ("flour", "all-purpose, unbleached"),
        // Dairy
        ("butter", "unsalted"),
        ("milk", "whole"),
        ("cheese", "sharp cheddar, grated"),
        ("yogurt", "plain, Greek"),
        ("cream", "heavy whipping"),
        // Herbs & Spices
        ("salt", "kosher"),
        ("black pepper", "freshly ground"),
        ("cumin", "ground"),
        ("paprika", "smoked"),
        ("oregano", "dried")
    ]
    
    private static let quantities = [
        "1", "2", "3", "4", "1/2", "1/4", "1/3", "3/4"
    ]
    
    private static let units = [
        ("cup", "cups"),
        ("tablespoon", "tablespoons"),
        ("teaspoon", "teaspoons"),
        ("pound", "pounds"),
        ("ounce", "ounces"),
        ("gram", "grams"),
        ("clove", "cloves"),
        ("pinch", "pinches"),
        ("handful", "handfuls")
    ]
    
    private static let preparations = [
        "finely chopped",
        "roughly chopped",
        "diced",
        "minced",
        "sliced",
        "grated",
        "crushed",
        "at room temperature",
        "chilled"
    ]
    
    // Add recipe templates
    private static let recipeTemplates: [String: [(ingredient: String, quality: String, defaultQuantity: String, unit: String)]] = [
        "5-Minute Microwave Oatmeal": [
            ("oats", "old-fashioned rolled", "1/2", "cup"),
            ("milk", "whole or plant-based", "3/4", "cup"),
            ("banana", "ripe, mashed", "1/2", "piece"),
            ("honey", "pure", "1", "tablespoon"),
            ("cinnamon", "ground", "1/4", "teaspoon"),
            ("salt", "kosher", "1", "pinch")
        ],
        "Quick Avocado Toast": [
            ("bread", "whole grain, sliced", "2", "slices"),
            ("avocado", "ripe, medium", "1", "piece"),
            ("olive oil", "extra virgin", "1", "teaspoon"),
            ("salt", "kosher", "1/4", "teaspoon"),
            ("black pepper", "freshly ground", "1", "pinch"),
            ("red pepper flakes", "crushed", "1", "pinch")
        ],
        "3-Minute Scrambled Eggs": [
            ("eggs", "large, free-range", "3", "pieces"),
            ("butter", "unsalted", "1", "tablespoon"),
            ("milk", "whole", "1", "tablespoon"),
            ("salt", "kosher", "1/4", "teaspoon"),
            ("black pepper", "freshly ground", "1", "pinch")
        ],
        "Classic Pasta Carbonara": [
            ("pasta", "spaghetti", "1", "pound"),
            ("eggs", "large, room temperature", "3", "pieces"),
            ("parmesan cheese", "freshly grated", "1", "cup"),
            ("pancetta", "diced", "8", "ounces"),
            ("garlic", "fresh", "2", "cloves"),
            ("black pepper", "freshly ground", "1", "teaspoon"),
            ("olive oil", "extra virgin", "2", "tablespoons")
        ],
        "Chicken Stir Fry": [
            ("chicken breast", "boneless, skinless", "1", "pound"),
            ("broccoli", "fresh, cut into florets", "2", "cups"),
            ("carrots", "julienned", "2", "pieces"),
            ("bell peppers", "red, sliced", "1", "piece"),
            ("soy sauce", "low-sodium", "3", "tablespoons"),
            ("garlic", "minced", "3", "cloves"),
            ("ginger", "fresh, grated", "1", "tablespoon"),
            ("vegetable oil", "for stir-frying", "2", "tablespoons")
        ]
    ]
    
    private static func generateIngredients(for recipe: String) -> [String] {
        // If we have a template for this recipe, use it
        if let template = recipeTemplates[recipe] {
            return template.map { ingredient in
                let (name, quality, quantity, unit) = ingredient
                // Add some variation to quantities (±20%) while keeping the unit
                let baseQuantity = Double(quantity.replacingOccurrences(of: "/", with: ".")) ?? 1.0
                let variation = Double.random(in: 0.8...1.2)
                let adjustedQuantity = baseQuantity * variation
                
                // Format the quantity nicely
                let formattedQuantity = String(format: "%.1f", adjustedQuantity)
                    .replacingOccurrences(of: ".0", with: "")
                
                return "\(formattedQuantity) \(unit) \(quality) \(name)"
            }
        }
        
        // For recipes without templates, generate semi-random but cuisine-appropriate ingredients
        var ingredients = Set<String>()
        let count = Int.random(in: 5...12)
        
        while ingredients.count < count {
            let (ingredient, quality) = commonIngredients.randomElement()!
            let quantity = quantities.randomElement()!
            let (unit, pluralUnit) = units.randomElement()!
            let preparation = preparations.randomElement()!
            
            let unitToUse = (quantity == "1") ? unit : pluralUnit
            let includePrep = Bool.random()
            let prepPhrase = includePrep ? ", \(preparation)" : ""
            
            let detailedIngredient = "\(quantity) \(unitToUse) \(quality) \(ingredient)\(prepPhrase)"
            ingredients.insert(detailedIngredient)
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
        
        let ingredients = generateIngredients(for: meal.title)
        let description = "A delicious \(meal.type.lowercased()) recipe that's perfect for any \(meal.type.lowercased()) occasion."
        
        // Create a more detailed ingredientsText for better semantic search
        let ingredientsText = """
            \(meal.title). This is a \(cuisineTypes.randomElement()!) \(meal.type.lowercased()) that takes \(meal.time) minutes to prepare. \
            \(description) \
            This recipe includes the following ingredients: \(ingredients.joined(separator: ", ")). \
            Perfect for \(["beginners", "home cooks", "busy weeknights", "meal prep", "special occasions"].randomElement()!). \
            This dish is \(["easy to make", "quick to prepare", "perfect for the family", "great for entertaining", "budget-friendly"].randomElement()!) \
            and \(["healthy", "nutritious", "satisfying", "delicious", "flavorful"].randomElement()!). \
            Cooking method includes \(["baking", "sautéing", "grilling", "roasting", "steaming", "stir-frying"].randomElement()!). \
            Great for \(meal.type == "Breakfast" ? "starting your day" :
                      meal.type == "Lunch" ? "a midday meal" :
                      meal.type == "Dinner" ? "an evening meal" :
                      meal.type == "Snack" ? "a quick bite" : "dessert"). \
            Dietary notes: \(["vegetarian-friendly", "can be made gluten-free", "protein-rich", "low-carb option available", "dairy-free option available"].randomElement()!).
            """
        
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