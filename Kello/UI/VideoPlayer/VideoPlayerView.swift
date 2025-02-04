import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: String
    let isVisible: Bool
    
    @StateObject private var playerManager = VideoPlayerManager.shared
    @State private var player: AVPlayer?
    @State private var loadError: Error?
    
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
            await loadPlayer()
        }
        .onChange(of: isVisible) { oldValue, newValue in
            playerManager.handleVisibilityChange(for: videoURL, isVisible: newValue)
            if newValue, let player = player {
                player.play()
            }
        }
    }
    
    private func loadPlayer() async {
        do {
            loadError = nil
            player = try await playerManager.player(for: videoURL, isVisible: isVisible)
            if isVisible {
                player?.play()
            }
        } catch {
            loadError = error
        }
    }
}

struct PlayerContainerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> PlayerContainerViewController {
        PlayerContainerViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: PlayerContainerViewController, context: Context) {
        uiViewController.updatePlayer(player)
    }
}

final class PlayerContainerViewController: UIViewController {
    private var player: AVPlayer
    private var playerLayer: AVPlayerLayer?
    private var isLayouting = false
    private var timeObserver: Any?
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard !isLayouting else { return }
        isLayouting = true
        defer { isLayouting = false }
        
        if playerLayer?.frame != view.bounds {
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
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
        
        view.backgroundColor = .black
        view.layer.masksToBounds = true
        playerLayer.opacity = 1.0
        
        player.play()
        
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            if self?.player.rate == 0 {
                self?.player.play()
            }
        }
        
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
            
            if status == .readyToPlay {
                player.play()
            }
        }
    }
    
    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}

#Preview {
    VideoPlayerView(videoURL: "https://example.com/sample.mp4", isVisible: true)
        .frame(height: 400)
        .background(Color.black)
} 