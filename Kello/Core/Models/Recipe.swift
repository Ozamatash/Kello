import Foundation
import SwiftData

@Model
class Recipe: Identifiable, Equatable {
    var id: String
    var title: String
    var recipeDescription: String
    var cookingTime: Int // in minutes
    var cuisineType: String
    var mealType: String
    var ingredients: [String]
    var steps: [String]
    var videoURL: String
    var thumbnailURL: String
    var createdAt: Date
    var updatedAt: Date
    
    // Engagement metrics
    var likes: Int
    var comments: Int
    var shares: Int
    var isLikedByCurrentUser: Bool
    
    // Nutritional information
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    
    // Vector Search fields
    var embedding: [Double]?
    var embeddingStatus: String?
    
    // Computed property for semantic search
    var ingredientsText: String {
        let ingredientsList = ingredients.joined(separator: ", ")
        return "\(title). \(recipeDescription). Ingredients: \(ingredientsList)"
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         cookingTime: Int,
         cuisineType: String,
         mealType: String = "Dinner", // Default to dinner if not specified
         ingredients: [String],
         steps: [String],
         videoURL: String,
         thumbnailURL: String,
         calories: Int? = nil,
         protein: Double? = nil,
         carbs: Double? = nil,
         fat: Double? = nil,
         embedding: [Double]? = nil,
         embeddingStatus: String? = nil,
         isLikedByCurrentUser: Bool = false) {
        self.id = id
        self.title = title
        self.recipeDescription = description
        self.cookingTime = cookingTime
        self.cuisineType = cuisineType
        self.mealType = mealType
        self.ingredients = ingredients
        self.steps = steps
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.likes = 0
        self.comments = 0
        self.shares = 0
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.embedding = embedding
        self.embeddingStatus = embeddingStatus
    }
} 