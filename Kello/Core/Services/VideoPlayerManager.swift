import Foundation
import AVFoundation
import FirebaseStorage
import os

@MainActor
final class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let storage = Storage.storage()
    private var activeRequests: [String: Task<AVPlayer, Error>] = [:]
    private var currentPreloadTask: Task<Void, Never>?
    private var videoFiles: [String: URL] = [:] // Keep track of video files
    private var activePlayers: [String: AVPlayer] = [:] // Keep track of active players
    
    // Logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.kello", category: "VideoPlayer")
    
    private init() {
        logger.info("VideoPlayerManager initialized")
        
        // Log initial cache stats
        let cache = URLCache.shared
        logger.info("Initial cache stats - memoryCapacity: \(cache.memoryCapacity), diskCapacity: \(cache.diskCapacity)")
        
        // Configure URL session for better caching
        URLSession.shared.configuration.requestCachePolicy = .returnCacheDataElseLoad
        URLSession.shared.configuration.urlCache?.memoryCapacity = 100 * 1024 * 1024  // 100 MB
        URLSession.shared.configuration.urlCache?.diskCapacity = 1000 * 1024 * 1024   // 1 GB
    }
    
    deinit {
        // Clean up video files
        for url in videoFiles.values {
            try? FileManager.default.removeItem(at: url)
        }
        // Cleanup all time observers
        for (player, observer) in timeObservers {
            player.removeTimeObserver(observer)
        }
        timeObservers.removeAll()
    }
    
    func player(for url: String, isVisible: Bool) async throws -> AVPlayer {
        logger.info("🎬 Requesting player for URL: \(url), isVisible: \(isVisible)")
        isLoading = true
        defer { isLoading = false }
        
        // If we already have an active player, use it
        if let existingPlayer = activePlayers[url] {
            logger.info("♻️ Reusing existing player for URL: \(url)")
            if isVisible {
                logger.info("▶️ Playing existing player for URL: \(url)")
                await existingPlayer.seek(to: .zero)
                existingPlayer.play()
            }
            return existingPlayer
        }
        
        // If there's already an active request for this URL, wait for it
        if let existingRequest = activeRequests[url] {
            logger.info("📝 Using existing request for URL: \(url)")
            let player = try await existingRequest.value
            activePlayers[url] = player
            if isVisible {
                logger.info("▶️ Playing existing player for URL: \(url)")
                await player.seek(to: .zero)
                player.play()
            }
            return player
        }
        
        // Create a new request task
        logger.info("🆕 Creating new player request for URL: \(url)")
        let task = Task<AVPlayer, Error> {
            defer { 
                activeRequests.removeValue(forKey: url)
                logger.info("🗑 Removed active request for URL: \(url)")
            }
            
            // Retry logic for network issues
            var retryCount = 0
            let maxRetries = 3
            
            while true {
                do {
                    let player = try await createPlayer(from: url)
                    activePlayers[url] = player
                    if isVisible {
                        logger.info("▶️ Playing new player for URL: \(url)")
                        await player.seek(to: .zero)
                        player.play()
                    }
                    return player
                } catch {
                    retryCount += 1
                    logger.error("❌ Attempt \(retryCount) failed: \(error.localizedDescription)")
                    if retryCount >= maxRetries {
                        throw error
                    }
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * retryCount)) // Exponential backoff
                }
            }
        }
        
        activeRequests[url] = task
        return try await task.value
    }
    
    func preloadVideos(_ urls: [String]) {
        // Cancel any existing preload task
        currentPreloadTask?.cancel()
        
        // Only preload the next video
        guard let nextVideoURL = urls.first,
              activeRequests[nextVideoURL] == nil else { return }
        
        // Start new preload task
        currentPreloadTask = Task {
            do {
                // Just create the request to trigger caching
                let request = try await createURLRequest(from: nextVideoURL)
                _ = try? await URLSession.shared.data(for: request)
            } catch {
                print("Failed to preload video: \(error.localizedDescription)")
            }
        }
    }
    
    func handleVisibilityChange(for url: String, isVisible: Bool) {
        logger.info("👁 Visibility changed for URL: \(url), isVisible: \(isVisible)")
        
        // First check active players
        if let player = activePlayers[url] {
            if isVisible {
                logger.info("▶️ Playing video for URL: \(url)")
                Task {
                    await player.seek(to: .zero)
                    player.play()
                }
            } else {
                logger.info("⏸ Pausing video for URL: \(url)")
                player.pause()
            }
            return
        }
        
        // If no active player, check requests
        guard let task = activeRequests[url] else {
            logger.warning("⚠️ No active player found for URL: \(url)")
            return
        }
        
        Task {
            if let player = try? await task.value {
                if isVisible {
                    logger.info("▶️ Playing video for URL: \(url)")
                    await player.seek(to: .zero)
                    player.play()
                } else {
                    logger.info("⏸ Pausing video for URL: \(url)")
                    player.pause()
                }
            } else {
                logger.error("❌ Failed to get player for visibility change, URL: \(url)")
            }
        }
    }
    
    private func createURLRequest(from urlString: String) async throws -> URLRequest {
        logger.info("🔗 Creating URL request for: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("❌ Invalid URL: \(urlString)")
            throw VideoPlayerError.invalidURL
        }
        
        // Get Firebase download URL if needed
        let downloadURL: URL
        if urlString.contains("firebasestorage.googleapis.com") {
            logger.info("🔥 Getting Firebase download URL for: \(urlString)")
            let storageRef = storage.reference(forURL: urlString)
            downloadURL = try await storageRef.downloadURL()
            logger.info("✅ Firebase download URL obtained: \(downloadURL)")
        } else {
            downloadURL = url
        }
        
        var request = URLRequest(url: downloadURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        return request
    }
    
    private func createPlayer(from urlString: String) async throws -> AVPlayer {
        logger.info("🎥 Creating player for URL: \(urlString)")
        
        // If we already have a video file, use it
        if let existingFileURL = videoFiles[urlString] {
            logger.info("📂 Using existing video file")
            return try await createPlayerFromFile(existingFileURL)
        }
        
        let request = try await createURLRequest(from: urlString)
        
        // Load the data with caching
        logger.info("📥 Loading video data...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log cache status and response details
        if let httpResponse = response as? HTTPURLResponse {
            logger.info("📡 HTTP Status: \(httpResponse.statusCode)")
            logger.info("📦 Content-Type: \(httpResponse.mimeType ?? "unknown")")
            logger.info("📊 Data size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        }
        
        // Create a persistent file to store the video data
        let fileManager = FileManager.default
        let videoDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("videos", isDirectory: true)
        
        try fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
        
        let videoFileURL = videoDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try data.write(to: videoFileURL)
        videoFiles[urlString] = videoFileURL
        logger.info("📝 Created video file at: \(videoFileURL)")
        
        return try await createPlayerFromFile(videoFileURL)
    }
    
    private func createPlayerFromFile(_ fileURL: URL) async throws -> AVPlayer {
        // Create asset with options for better playback
        let asset = AVURLAsset(
            url: fileURL,
            options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetHTTPHeaderFieldsKey": ["Accept": "video/mp4"]
            ]
        )
        
        // Check if the asset is playable
        do {
            guard try await asset.load(.isPlayable) else {
                logger.error("❌ Asset is not playable")
                throw VideoPlayerError.assetNotPlayable
            }
            logger.info("✅ Asset is playable")
            
            // Load and log track information
            let tracks = try await asset.loadTracks(withMediaType: .video)
            logger.info("🎞 Video tracks count: \(tracks.count)")
            if let track = tracks.first {
                let dimensions = try await track.load(.naturalSize)
                logger.info("📐 Video dimensions: \(dimensions.width)x\(dimensions.height)")
            }
        } catch {
            logger.error("❌ Failed to load asset: \(error.localizedDescription)")
            throw error
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 10
        
        // Configure player for better playback
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false // Changed to false to force immediate playback
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = true
        
        // Wait for player item to be ready with timeout
        let readyTimeout = Task {
            for await status in playerItem.publisher(for: \.status).values {
                if status == .readyToPlay {
                    logger.info("✅ PlayerItem ready to play")
                    return true
                } else if status == .failed {
                    if let error = playerItem.error {
                        logger.error("❌ PlayerItem failed: \(error.localizedDescription)")
                        throw error
                    }
                }
            }
            return false
        }
        
        // Add playback observation
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak player] time in
            self.logger.info("⏱ Playback time: \(time.seconds), rate: \(player?.rate ?? 0)")
            
            // If video is not playing and should be, try to restart it
            if let player = player, player.rate == 0 && time.seconds > 0 {
                player.play()
            }
        }
        
        // Store time observer for cleanup
        timeObservers[player] = timeObserver
        
        // Force playback to start
        player.play()
        
        logger.info("✅ Successfully created player")
        return player
    }
    
    private var timeObservers: [AVPlayer: Any] = [:]
    
    private func storeTimeObserver(_ observer: Any, for player: AVPlayer) {
        timeObservers[player] = observer
    }
    
    private func cleanupTimeObserver(for player: AVPlayer) {
        if let observer = timeObservers[player] {
            player.removeTimeObserver(observer)
            timeObservers.removeValue(forKey: player)
        }
    }
    
    private func monitorPlayerItem(_ playerItem: AVPlayerItem) async {
        for await status in playerItem.publisher(for: \.status).values {
            switch status {
            case .readyToPlay:
                logger.info("✅ PlayerItem ready to play")
            case .failed:
                if let error = playerItem.error {
                    logger.error("❌ PlayerItem failed: \(error.localizedDescription)")
                }
            default:
                logger.info("ℹ️ PlayerItem status changed: \(status.rawValue)")
            }
        }
    }
}

enum VideoPlayerError: Error {
    case invalidURL
    case assetNotPlayable
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid video URL"
        case .assetNotPlayable: return "Video cannot be played"
        }
    }
}