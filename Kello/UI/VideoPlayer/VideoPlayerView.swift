import SwiftUI
import AVKit
import AVFoundation
import os

struct VideoPlayerView: View {
    let videoURL: String
    let isVisible: Bool
    
    @StateObject private var playerManager = VideoPlayerManager.shared
    @State private var player: AVPlayer?
    @State private var loadError: Error?
    @State private var isPlayerReady = false
    
    // Logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.kello", category: "VideoPlayerView")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let error = loadError ?? playerManager.error {
                    VStack(spacing: 12) {
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
                        Button("Retry") {
                            Task {
                                logger.info("🔄 Retrying video load for URL: \(videoURL)")
                                await loadPlayer()
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                } else if let player = player {
                    PlayerContainerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            logger.info("📺 PlayerContainerView appeared")
                            if isVisible {
                                player.play()
                            }
                        }
                } else if playerManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .task {
            logger.info("🎬 VideoPlayerView task started for URL: \(videoURL)")
            await loadPlayer()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            logger.info("👁 Visibility changed from \(oldValue) to \(newValue) for URL: \(videoURL)")
            playerManager.handleVisibilityChange(for: videoURL, isVisible: newValue)
            
            // Force playback if needed
            if newValue, let player = player {
                player.play()
            }
        }
    }
    
    private func loadPlayer() async {
        logger.info("📥 Loading player for URL: \(videoURL)")
        do {
            loadError = nil
            player = try await playerManager.player(for: videoURL, isVisible: isVisible)
            if isVisible {
                player?.play()
            }
            logger.info("✅ Successfully loaded player for URL: \(videoURL)")
        } catch {
            logger.error("❌ Failed to create player: \(error.localizedDescription)")
            print("Failed to create player: \(error)")
            loadError = error
        }
    }
}

struct PlayerContainerView: UIViewControllerRepresentable {
    let player: AVPlayer
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.kello", category: "PlayerContainer")
    
    func makeUIViewController(context: Context) -> PlayerContainerViewController {
        logger.info("🎮 Creating PlayerContainerViewController")
        return PlayerContainerViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
        logger.info("🔄 Updating PlayerContainerViewController")
        uiViewController.updatePlayer(player)
    }
}

final class PlayerContainerViewController: UIViewController {
    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.kello", category: "PlayerViewController")
    private var isLayouting = false
    private var timeObserver: Any?
    
    init(player: AVPlayer) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
        logger.info("🎮 PlayerContainerViewController initialized")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("👀 viewDidLoad called")
        setupPlayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.info("👀 viewDidAppear called")
        player.play()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Prevent layout loops
        guard !isLayouting else { return }
        isLayouting = true
        defer { isLayouting = false }
        
        // Only update frame if it actually changed
        if playerLayer?.frame != view.bounds {
            logger.info("📐 Updating player layer frame")
            playerLayer?.frame = view.bounds
        }
    }
    
    func updatePlayer(_ newPlayer: AVPlayer) {
        guard newPlayer !== player else { return }
        player = newPlayer
        playerLayer?.player = newPlayer
        player.play()
    }
    
    private func setupPlayer() {
        logger.info("🎬 Setting up player layer")
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        view.backgroundColor = .black
        view.layer.masksToBounds = true
        playerLayer.opacity = 1.0
        
        // Ensure video starts playing
        player.play()
        
        // Add periodic time observer for debugging
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.logger.info("⏱ Container playback time: \(time.seconds), rate: \(self?.player.rate ?? 0)")
            
            // If video is not playing, try to restart it
            if self?.player.rate == 0 {
                self?.player.play()
            }
        }
        
        // Observe player status
        player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                logger.info("✅ Player item is ready to play")
                player.play()
            case .failed:
                if let error = player.currentItem?.error {
                    logger.error("❌ Player item failed: \(error.localizedDescription)")
                }
            case .unknown:
                logger.info("❓ Player item status is unknown")
            @unknown default:
                logger.warning("⚠️ Unknown player item status")
            }
        }
    }
    
    deinit {
        logger.info("🗑 PlayerContainerViewController deinit")
        // Remove observers
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        // Clean up player layer
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
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