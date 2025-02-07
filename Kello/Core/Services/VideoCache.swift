import Foundation

/// Simple video caching service that stores videos in local files
class VideoCache {
    static let shared = VideoCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Get the cache directory path
        let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachePath.appendingPathComponent("VideoCache", isDirectory: true)
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getVideoURL(_ urlString: String) async throws -> URL {
        // Clean up Firebase Storage URLs
        let cleanedURLString = urlString
            .replacingOccurrences(of: "%252F", with: "%2F")
            .replacingOccurrences(of: "%25", with: "%")
        
        guard let url = URL(string: cleanedURLString) else {
            throw URLError(.badURL)
        }
        
        // Generate a filename from the URL's last component
        let filename = url.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(filename)
        
        // Check if file exists in cache
        if fileManager.fileExists(atPath: localURL.path) {
            print("🎥 Using cached video: \(filename)")
            return localURL
        }
        
        // Not in cache, download and cache the file
        print("🎥 Downloading video: \(filename)")
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Move the downloaded file to our cache directory
            if fileManager.fileExists(atPath: localURL.path) {
                try fileManager.removeItem(at: localURL)
            }
            try fileManager.moveItem(at: tempURL, to: localURL)
            
            print("🎥 Successfully cached video: \(filename)")
            return localURL
        } catch {
            print("❌ Failed to cache video: \(error.localizedDescription)")
            // If download fails but we're offline and have a cached version, use that
            if fileManager.fileExists(atPath: localURL.path) {
                print("🎥 Using existing cached video despite download failure: \(filename)")
                return localURL
            }
            throw error
        }
    }
    
    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try fileManager.removeItem(at: file)
            }
            print("🗑️ Video cache cleared")
        } catch {
            print("❌ Failed to clear video cache: \(error.localizedDescription)")
        }
    }
    
    /// Get the size of the cache in bytes
    func getCacheSize() -> Int64 {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return try contents.reduce(0) { total, url in
                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                return total + Int64(resourceValues.fileSize ?? 0)
            }
        } catch {
            print("❌ Failed to calculate cache size: \(error.localizedDescription)")
            return 0
        }
    }
} 