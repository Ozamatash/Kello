import Foundation

/// Simple video caching service that utilizes URLCache
class VideoCache {
    static let shared = VideoCache()
    private init() {}
    
    func getVideoURL(_ urlString: String) async throws -> URL {
        // Clean up Firebase Storage URLs
        let cleanedURLString = urlString
            .replacingOccurrences(of: "%252F", with: "%2F")
            .replacingOccurrences(of: "%25", with: "%")
        
        guard let url = URL(string: cleanedURLString) else {
            throw URLError(.badURL)
        }
        
        // Create request with cache policy
        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 30
        )
        
        // Check cache first
        if URLCache.shared.cachedResponse(for: request) != nil {
            print("🎥 Using cached video: \(url.lastPathComponent)")
            return url
        }
        
        // Not in cache, start background caching and return URL immediately
        print("🎥 Streaming video: \(url.lastPathComponent)")
        Task {
            do {
                let (_, _) = try await URLSession.shared.data(for: request)
                print("🎥 Background caching complete: \(url.lastPathComponent)")
            } catch {
                print("❌ Background caching failed: \(error.localizedDescription)")
            }
        }
        
        return url
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
} 