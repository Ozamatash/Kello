import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: String
    let nextVideoURL: String?
    let isVisible: Bool
    @State private var queuePlayer: AVQueuePlayer?
    @State private var isPlaying = true
    
    // Track preloaded assets
    @State private var currentAsset: AVAsset?
    @State private var nextAsset: AVAsset?
    
    var body: some View {
        ZStack {
            if let player = queuePlayer {
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .aspectRatio(contentMode: .fill)
                    // Add black background to avoid any potential gaps
                    .background(Color.black)
                    // Clip any content that overflows
                    .clipped()
                    // Add tap gesture overlay
                    .overlay(Color.black.opacity(0.001))
                    .onTapGesture {
                        if isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                        isPlaying.toggle()
                    }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .background(Color.black)
        .task {
            if currentAsset == nil {
                await preloadAssets()
                if isVisible {
                    setupPlayer()
                }
            }
        }
        .onAppear {
            if isVisible && queuePlayer == nil {
                setupPlayer()
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                setupPlayer()
            } else {
                cleanup()
            }
        }
    }
    
    private func preloadAssets() async {
        // Preload current video
        if let url = URL(string: videoURL) {
            let asset = AVURLAsset(url: url)
            await asset.loadValues(forKeys: ["playable", "duration"])
            currentAsset = asset
        }
        
        // Preload next video if available
        if let nextURL = nextVideoURL,
           let url = URL(string: nextURL) {
            let asset = AVURLAsset(url: url)
            await asset.loadValues(forKeys: ["playable", "duration"])
            nextAsset = asset
        }
    }
    
    private func setupPlayer() {
        guard queuePlayer == nil else { return }
        
        // Create player items from preloaded assets
        let currentItem: AVPlayerItem
        if let asset = currentAsset {
            currentItem = AVPlayerItem(asset: asset)
        } else if let url = URL(string: videoURL) {
            currentItem = AVPlayerItem(url: url)
        } else {
            return
        }
        
        let player = AVQueuePlayer(playerItem: currentItem)
        
        // Add preloaded next item if available
        if let nextAsset = nextAsset {
            let nextItem = AVPlayerItem(asset: nextAsset)
            player.insert(nextItem, after: currentItem)
        }
        
        // Enable looping
        player.actionAtItemEnd = .advance
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: currentItem,
            queue: .main
        ) { _ in
            // Create a new item for looping
            if let asset = currentAsset {
                let newItem = AVPlayerItem(asset: asset)
                player.insert(newItem, after: nil)
            }
        }
        
        self.queuePlayer = player
        player.play()
    }
    
    private func cleanup() {
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        queuePlayer = nil
        isPlaying = false
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanup()
    }
    
    private func cleanup() {
        statusObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        if let loopObserver = loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    deinit {
        cleanup()
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
        VideoPlayerView(videoURL: "https://example.com/sample.mp4", nextVideoURL: nil, isVisible: true)
            .frame(height: 400)
            .background(Color.black)
    }
} 