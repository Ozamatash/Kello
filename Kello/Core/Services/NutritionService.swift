import Foundation

class NutritionService {
    static let shared = NutritionService()
    
    private var openAIKey: String {
        guard let path = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let apiKey = dict["API_KEY"] as? String else {
            fatalError("OpenAI API key not found. Please add OpenAI-Info.plist with API_KEY.")
        }
        return apiKey
    }
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    struct NutritionalInfo: Codable {
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let servings: Int
        let caloriesPerServing: Int
    }
    
    func analyzeRecipe(title: String, description: String, ingredients: [String]) async throws -> NutritionalInfo {
        let recipeContext = """
        Recipe: \(title)
        Description: \(description)
        Ingredients:
        \(ingredients.joined(separator: "\n"))
        """
        
        let headers = [
            "Authorization": "Bearer \(openAIKey)",
            "Content-Type": "application/json"
        ]
        
        let systemPrompt = """
        You are a nutritional analysis expert. Analyze the recipe ingredients and portions to estimate nutritional values.
        First, estimate the number of servings this recipe makes based on the ingredients and recipe type.
        Then provide the nutritional information PER SERVING in a JSON format with the following fields:
        - calories (integer, total calories per serving)
        - protein (double, grams of protein per serving)
        - carbs (double, grams of carbohydrates per serving)
        - fat (double, grams of fat per serving)
        - servings (integer, estimated number of servings this recipe makes)
        - caloriesPerServing (integer, calories per serving)
        
        Base your calculations on standard serving sizes and common ingredient portions.
        If ingredient quantities are not specified, make reasonable assumptions based on the recipe type and cooking time.
        Return ONLY the JSON object, no additional text.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": recipeContext]
            ]
        ]
        
        guard let url = URL(string: openAIEndpoint),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "NutritionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create request"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "NutritionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "OpenAI API error"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "NutritionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }
        
        // Clean up the response
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
        
        guard let jsonData = cleanContent.data(using: .utf8),
              let nutritionalInfo = try? JSONDecoder().decode(NutritionalInfo.self, from: jsonData) else {
            throw NSError(domain: "NutritionService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse nutritional information"])
        }
        
        return nutritionalInfo
    }
} 