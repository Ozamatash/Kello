import Foundation

enum OpenAIConfig {
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let apiKey = dict["API_KEY"] as? String else {
            fatalError("OpenAI API key not found. Please add OpenAI-Info.plist with API_KEY.")
        }
        return apiKey
    }
} 