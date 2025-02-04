import Foundation
import AVFoundation
import FirebaseStorage

@MainActor
final class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()
    
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let storage = Storage.storage()
    private var activeRequests: [String: Task<AVPlayer, Error>] = [:]
    private var currentPreloadTask: Task<Void, Never>?
    private var videoFiles: [String: URL] = [:]
    private var activePlayers: [String: AVPlayer] = [:]
    private var timeObservers: [AVPlayer: Any] = [:]
    
    private init() {
        URLSession.shared.configuration.requestCachePolicy = .returnCacheDataElseLoad
        URLSession.shared.configuration.urlCache?.memoryCapacity = 100 * 1024 * 1024  // 100 MB
        URLSession.shared.configuration.urlCache?.diskCapacity = 1000 * 1024 * 1024   // 1 GB
    }
    
    deinit {
        for url in videoFiles.values {
            try? FileManager.default.removeItem(at: url)
        }
        for (player, observer) in timeObservers {
            player.removeTimeObserver(observer)
        }
        timeObservers.removeAll()
    }
    
    func player(for url: String, isVisible: Bool) async throws -> AVPlayer {
        isLoading = true
        defer { isLoading = false }
        
        if let existingPlayer = activePlayers[url] {
            if isVisible {
                await existingPlayer.seek(to: .zero)
                existingPlayer.play()
            }
            return existingPlayer
        }
        
        if let existingRequest = activeRequests[url] {
            let player = try await existingRequest.value
            activePlayers[url] = player
            if isVisible {
                await player.seek(to: .zero)
                player.play()
            }
            return player
        }
        
        let task = Task<AVPlayer, Error> {
            defer { activeRequests.removeValue(forKey: url) }
            
            var retryCount = 0
            let maxRetries = 3
            
            while true {
                do {
                    let player = try await createPlayer(from: url)
                    activePlayers[url] = player
                    if isVisible {
                        await player.seek(to: .zero)
                        player.play()
                    }
                    return player
                } catch {
                    retryCount += 1
                    if retryCount >= maxRetries {
                        throw error
                    }
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000 * retryCount))
                }
            }
        }
        
        activeRequests[url] = task
        return try await task.value
    }
    
    func preloadVideos(_ urls: [String]) {
        currentPreloadTask?.cancel()
        
        guard let nextVideoURL = urls.first,
              activeRequests[nextVideoURL] == nil else { return }
        
        currentPreloadTask = Task {
            do {
                let request = try await createURLRequest(from: nextVideoURL)
                _ = try? await URLSession.shared.data(for: request)
            } catch {
                print("Failed to preload video: \(error.localizedDescription)")
            }
        }
    }
    
    func handleVisibilityChange(for url: String, isVisible: Bool) {
        if let player = activePlayers[url] {
            if isVisible {
                Task {
                    await player.seek(to: .zero)
                    player.play()
                }
            } else {
                player.pause()
            }
            return
        }
        
        guard let task = activeRequests[url] else { return }
        
        Task {
            if let player = try? await task.value {
                if isVisible {
                    await player.seek(to: .zero)
                    player.play()
                } else {
                    player.pause()
                }
            }
        }
    }
    
    private func createURLRequest(from urlString: String) async throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw VideoPlayerError.invalidURL
        }
        
        let downloadURL: URL
        if urlString.contains("firebasestorage.googleapis.com") {
            let storageRef = storage.reference(forURL: urlString)
            downloadURL = try await storageRef.downloadURL()
        } else {
            downloadURL = url
        }
        
        var request = URLRequest(url: downloadURL)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        return request
    }
    
    private func createPlayer(from urlString: String) async throws -> AVPlayer {
        if let existingFileURL = videoFiles[urlString] {
            return try await createPlayerFromFile(existingFileURL)
        }
        
        let request = try await createURLRequest(from: urlString)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let fileManager = FileManager.default
        let videoDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("videos", isDirectory: true)
        
        try fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
        
        let videoFileURL = videoDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try data.write(to: videoFileURL)
        videoFiles[urlString] = videoFileURL
        
        return try await createPlayerFromFile(videoFileURL)
    }
    
    private func createPlayerFromFile(_ fileURL: URL) async throws -> AVPlayer {
        let asset = AVURLAsset(
            url: fileURL,
            options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetHTTPHeaderFieldsKey": ["Accept": "video/mp4"]
            ]
        )
        
        guard try await asset.load(.isPlayable) else {
            throw VideoPlayerError.assetNotPlayable
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 10
        
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = true
        
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak player] time in
            if let player = player, player.rate == 0 && time.seconds > 0 {
                player.play()
            }
        }
        
        timeObservers[player] = timeObserver
        player.play()
        
        return player
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