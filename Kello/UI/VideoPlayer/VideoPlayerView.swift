import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: String
    let isVisible: Bool
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var error: Error?
    
    // Add debug logging
    private func logPlayerStatus() {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        print("=== Video Player Debug Info ===")
        print("URL: \(videoURL)")
        print("Player Status: \(player.status.rawValue)")
        print("Item Status: \(currentItem.status.rawValue)")
        print("Item Duration: \(currentItem.duration.seconds)")
        print("Item Tracks: \(currentItem.tracks.count)")
        print("Is Visible: \(isVisible)")
        if let error = currentItem.error {
            print("Item Error: \(error)")
        }
        print("===========================")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Failed to load video")
                            .foregroundColor(.white)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if let player = player {
                    PlayerContainerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .onAppear {
            setupAudioSession()
            setupPlayer()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            handleVisibilityChange(isVisible: newValue)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func handleVisibilityChange(isVisible: Bool) {
        guard let player = player else { return }
        
        if isVisible {
            // Reset the player item when becoming visible
            if player.currentItem?.status == .failed {
                replacePlayerItem()
            }
            player.seek(to: .zero)
            player.volume = 1.0
            player.play()
            logPlayerStatus()
        } else {
            player.pause()
            player.volume = 0.0
        }
    }
    
    private func replacePlayerItem() {
        guard let player = player,
              let currentItem = player.currentItem,
              let asset = currentItem.asset as? AVURLAsset else { return }
        
        // Create a new player item with the same asset
        let newPlayerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: newPlayerItem)
    }
    
    private func createPlayer(from urlString: String) async throws -> AVPlayer {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "VideoPlayerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Create a cacheable request
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30
        
        // Check if we have cached data
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            print("📦 Using cached video data: \(ByteCountFormatter.string(fromByteCount: Int64(cachedResponse.data.count), countStyle: .file))")
        } else {
            print("🌐 No cached data available, loading from network")
        }
        
        // Create session configuration with caching
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache.shared
        
        // Load the data with caching
        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: request)
        
        // Cache the response if it's not already cached
        if URLCache.shared.cachedResponse(for: request) == nil {
            let cachedResponse = CachedURLResponse(
                response: response,
                data: data,
                storagePolicy: .allowed
            )
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            print("💾 Cached video data: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        }
        
        // Create a temporary file to store the video data
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try data.write(to: tempFileURL)
        
        // Create asset from the temporary file
        let asset = AVURLAsset(url: tempFileURL)
        
        // Preload essential properties
        await asset.loadValues(forKeys: ["playable", "duration"])
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 10
        
        // Create player and set it to automatically loop
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none // Prevent player from stopping at end
        
        return player
    }
    
    private func setupPlayer() {
        Task {
            do {
                let player = try await createPlayer(from: videoURL)
                player.volume = isVisible ? 1.0 : 0.0
                
                await MainActor.run {
                    self.player = player
                    if isVisible {
                        player.play()
                    }
                    isLoading = false
                }
            } catch {
                print("❌ Player setup error: \(error)")
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
}

// Player container to handle KVO
final class PlayerContainerViewController: UIViewController {
    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer?
    private var statusObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    private var loopObserver: NSObjectProtocol?
    
    init(player: AVPlayer) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPlayer()
        setupObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
    
    private func setupPlayer() {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        // Ensure the layer is visible
        view.layer.masksToBounds = true
        playerLayer.opacity = 1.0
        
        // Enable background video loading
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        // Loop video - observe the player instead of a specific item
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let playerItem = notification.object as? AVPlayerItem,
                  playerItem == self.player.currentItem else { return }
            
            self.player.seek(to: .zero)
            self.player.play()
        }
    }
    
    private func setupObservers() {
        // Observe player item status
        statusObserver = player.currentItem?.observe(\.status, options: [.new, .old]) { [weak self] playerItem, change in
            switch playerItem.status {
            case .failed:
                if let error = playerItem.error {
                    print("Player item failed: \(error)")
                }
            case .readyToPlay:
                print("Player item ready to play")
                // Only play if the player should be playing
                if self?.player.rate != 0 {
                    self?.player.play()
                }
            case .unknown:
                print("Player item status unknown")
            @unknown default:
                break
            }
        }
        
        // Observe loaded time ranges to monitor buffering
        loadedTimeRangesObserver = player.currentItem?.observe(\.loadedTimeRanges) { [weak self] item, _ in
            guard let timeRange = item.loadedTimeRanges.first?.timeRangeValue else { return }
            let bufferedDuration = timeRange.duration.seconds
            let bufferedStart = timeRange.start.seconds
            print("Buffered from \(bufferedStart)s to \(bufferedStart + bufferedDuration)s")
        }
    }
    
    deinit {
        statusObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        if let loopObserver = loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }
}

// Bridge between SwiftUI and UIKit
struct PlayerContainerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> PlayerContainerViewController {
        return PlayerContainerViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
        // Update if needed
    }
}

// Preview provider for development
struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(videoURL: "https://example.com/sample.mp4", isVisible: true)
            .frame(height: 400)
            .background(Color.black)
    }
} 