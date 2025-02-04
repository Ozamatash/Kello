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
    private var videoFiles: [String: URL] = [:]
    private var activePlayers: [String: AVPlayer] = [:]
    private var timeObservers: [AVPlayer: Any] = [:]
    private var currentlyVisibleURL: String?
    
    // Debug logging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Kello", category: "VideoPlayer")
    
    // Debug state tracking
    private var playerStates: [String: String] = [:] {
        didSet {
            logger.debug("Player states updated: \(self.playerStates)")
        }
    }
    
    private init() {
        URLSession.shared.configuration.requestCachePolicy = .returnCacheDataElseLoad
        URLSession.shared.configuration.urlCache?.memoryCapacity = 100 * 1024 * 1024  // 100 MB
        URLSession.shared.configuration.urlCache?.diskCapacity = 1000 * 1024 * 1024   // 1 GB
        
        setupAudioSession()
        setupDebugNotifications()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            logger.debug("Audio session setup complete")
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupDebugNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        logger.debug("Audio session interruption: \(type.rawValue)")
        
        switch type {
        case .began:
            // Pause all active players
            pauseAllPlayers()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Only resume the currently visible player
                resumeVisiblePlayer()
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        logger.debug("Audio route changed: \(reason.rawValue)")
    }
    
    private func pauseAllPlayers() {
        for (url, player) in activePlayers {
            player.pause()
            playerStates[url] = "paused"
        }
    }
    
    private func resumeVisiblePlayer() {
        guard let visibleURL = playerStates.first(where: { $0.value == "visible" })?.key,
              let player = activePlayers[visibleURL] else {
            return
        }
        player.play()
        playerStates[visibleURL] = "playing"
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
        logger.debug("Visibility change for \(url): isVisible=\(isVisible)")
        
        if isVisible {
            // If there was a previously visible URL, handle its cleanup
            if let previousURL = currentlyVisibleURL, previousURL != url {
                stopAndRemovePlayer(for: previousURL)
            }
            
            currentlyVisibleURL = url
            playerStates[url] = "visible"
            
            // Stop all other players immediately
            for (playerURL, player) in activePlayers where playerURL != url {
                stopAndRemovePlayer(for: playerURL)
            }
            
            if let player = activePlayers[url] {
                Task {
                    // Reset and play the current video
                    await player.seek(to: .zero)
                    player.volume = 1.0
                    player.play()
                    playerStates[url] = "playing"
                    logger.debug("Playing video for \(url)")
                }
            }
        } else {
            if currentlyVisibleURL == url {
                currentlyVisibleURL = nil
            }
            
            if let player = activePlayers[url] {
                player.pause()
                player.volume = 0.0
                playerStates[url] = "paused"
                logger.debug("Paused video for \(url)")
                
                // If this player is not needed for preloading, remove it
                if currentlyVisibleURL == nil || !isAdjacentToVisible(url) {
                    stopAndRemovePlayer(for: url)
                }
            }
        }
    }
    
    private func isAdjacentToVisible(_ url: String) -> Bool {
        guard let visibleURL = currentlyVisibleURL,
              let urls = Array(activePlayers.keys) as? [String],
              let visibleIndex = urls.firstIndex(of: visibleURL),
              let currentIndex = urls.firstIndex(of: url) else {
            return false
        }
        
        return abs(currentIndex - visibleIndex) == 1
    }
    
    private func stopAndRemovePlayer(for url: String) {
        guard let player = activePlayers[url] else { return }
        
        // First pause and zero the volume
        player.pause()
        player.volume = 0.0
        
        // Remove the player item to stop any background loading
        player.replaceCurrentItem(with: nil)
        
        // Remove time observer
        if let observer = timeObservers[player] {
            player.removeTimeObserver(observer)
            timeObservers.removeValue(forKey: player)
        }
        
        // Remove from active players and states
        activePlayers.removeValue(forKey: url)
        playerStates.removeValue(forKey: url)
        
        logger.debug("Stopped and removed player for \(url)")
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
        player.volume = 0.0  // Start with volume at 0
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = true
        
        // Debug notification for item end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak player, weak self] time in
            guard let player = player,
                  let self = self,
                  let url = self.activePlayers.first(where: { $0.value === player })?.key else {
                return
            }
            
            // Only auto-play if this is the currently visible player
            guard url == self.currentlyVisibleURL,
                  player.rate == 0,
                  time.seconds > 0 else {
                return
            }
            
            self.logger.debug("Auto-playing stopped player at time: \(time.seconds)")
            player.volume = 1.0
            player.play()
        }
        
        timeObservers[player] = timeObserver
        
        return player
    }
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem,
              let playerEntry = activePlayers.first(where: { $0.value.currentItem === playerItem })
        else { return }
        
        let (url, player) = playerEntry
        guard let state = self.playerStates[url],
              state == "playing" || state == "visible" else {
            logger.debug("Ignoring end of video for \(url) in state: \(self.playerStates[url] ?? "unknown")")
            return
        }
        
        logger.debug("Player reached end for URL: \(url) - replaying")
        Task {
            await playerItem.seek(to: .zero)
            player.play()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        for url in videoFiles.values {
            try? FileManager.default.removeItem(at: url)
        }
        for (player, observer) in timeObservers {
            player.removeTimeObserver(observer)
        }
        timeObservers.removeAll()
        
        // Clean up audio session
        try? AVAudioSession.sharedInstance().setActive(false)
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