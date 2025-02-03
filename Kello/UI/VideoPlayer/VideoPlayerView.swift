import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: String
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
        if let error = currentItem.error {
            print("Item Error: \(error)")
        }
        print("===========================")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
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
                } else if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoURL) else {
            error = NSError(domain: "VideoPlayerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        self.player = player
        
        // Start playback after a short delay to ensure proper setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            player.play()
            isLoading = false
        }
    }
    
    private func cleanup() {
        player?.pause()
        NotificationCenter.default.removeObserver(self)
        player = nil
    }
}

// Player container to handle KVO
final class PlayerContainerViewController: UIViewController {
    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    init(player: AVPlayer) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
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
                self?.player.play()
            case .unknown:
                print("Player item status unknown")
            @unknown default:
                break
            }
        }
        
        // Add periodic time observer for debugging
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] _ in
            guard let self = self,
                  let playerItem = self.player.currentItem else { return }
            
            print("=== Video Player Debug Info ===")
            print("Player Status: \(self.player.status.rawValue)")
            print("Item Status: \(playerItem.status.rawValue)")
            print("Item Duration: \(playerItem.duration.seconds)")
            print("Item Tracks: \(playerItem.tracks.count)")
            if let error = playerItem.error {
                print("Item Error: \(error)")
            }
            print("===========================")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        statusObserver?.invalidate()
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
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
        VideoPlayerView(videoURL: "https://example.com/sample.mp4")
            .frame(height: 400)
            .background(Color.black)
    }
} 