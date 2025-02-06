import SwiftUI
import AVFoundation

/// A view model that loads a video asynchronously using AVFoundation,
/// creates an AVPlayer, and—for short looping videos—automatically restarts playback.
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var isReady = false
    @Published var isPlaying = false

    /// The underlying AVPlayer used for video playback.
    var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    /// Observer token for the end-of-playback notification.
    private var playbackObserver: NSObjectProtocol?

    /// The URL of the video asset.
    let videoURL: URL
    /// Whether the video should automatically loop.
    let shouldLoop: Bool
    /// Whether the video is currently visible
    private var isVisible: Bool

    /// Initializes the view model with a video URL string.
    /// - Parameters:
    ///   - url: A valid video URL string.
    ///   - shouldLoop: Indicates if the video should loop automatically (default is true).
    init(url: String, shouldLoop: Bool = true) {
        guard let url = URL(string: url) else {
            fatalError("Invalid video URL: \(url)")
        }
        self.videoURL = url
        self.shouldLoop = shouldLoop
        self.isVisible = false
    }

    /// Asynchronously prepares the player by loading the asset and setting up the player.
    func preparePlayer() async {
        let asset = AVURLAsset(url: videoURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true,
            AVURLAssetAllowsCellularAccessKey: true
        ])
        
        do {
            let isPlayable = try await asset.load(.isPlayable)
            if isPlayable {
                let item = AVPlayerItem(asset: asset)
                self.playerItem = item
                self.player = AVPlayer(playerItem: item)
                // Set initial volume to 0 to prevent audio bleed
                self.player?.volume = 0
                self.isReady = true
                
                // Only start playing if the view is visible
                if isVisible {
                    self.player?.volume = 1
                    self.play()
                } else {
                    // Preload by starting then immediately pausing
                    self.player?.play()
                    self.player?.pause()
                }
                
                if shouldLoop {
                    // Observe the end of playback, then seek to zero & resume.
                    playbackObserver = NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: item,
                        queue: .main) { [weak self] _ in
                            Task { @MainActor [weak self] in
                                guard let self = self else { return }
                                self.player?.seek(to: .zero)
                                if self.isVisible {
                                    self.play()
                                }
                            }
                        }
                }
            } else {
                print("Asset is not playable")
            }
        } catch {
            print("Error preparing player: \(error)")
        }
    }

    /// Starts playback.
    func play() {
        guard isVisible else { return }
        player?.volume = 1
        player?.play()
        isPlaying = true
    }

    /// Pauses playback.
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Toggles playback between play and pause.
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Updates the player based on its visibility.
    /// - Parameter isVisible: When `true`, plays the video; when `false`, pauses it.
    func handleVisibilityChange(isVisible: Bool) {
        self.isVisible = isVisible
        if isVisible {
            player?.volume = 1
            play()
        } else {
            player?.volume = 0
            pause()
        }
    }

    /// Cleans up the player and observers.
    func cleanup() {
        pause()
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playbackObserver = nil
        player = nil
        playerItem = nil
        isReady = false
    }
}

/// A SwiftUI view that displays the video player. It listens for tap gestures to toggle
/// play/pause and handles life-cycle events (onAppear/onDisappear) for cleanup.
struct VideoPlayerView: View {
    let videoURL: String
    let isVisible: Bool
    let shouldLoop: Bool

    /// The view model is created with the video URL.
    @StateObject private var viewModel: VideoPlayerViewModel

    init(videoURL: String, isVisible: Bool, shouldLoop: Bool = true) {
        self.videoURL = videoURL
        self.isVisible = isVisible
        self.shouldLoop = shouldLoop
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(url: videoURL, shouldLoop: shouldLoop))
    }

    var body: some View {
        ZStack {
            if viewModel.isReady {
                VideoPlayerContainerView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                    // Toggle playback when the view is tapped.
                    .onTapGesture {
                        viewModel.togglePlayback()
                    }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .background(Color.black)
        .onAppear {
            Task {
                await viewModel.preparePlayer()
            }
        }
        .onChange(of: isVisible) { _, newValue in
            viewModel.handleVisibilityChange(isVisible: newValue)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

/// A UIViewControllerRepresentable that hosts our AVPlayerLayer within SwiftUI.
struct VideoPlayerContainerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel

    func makeUIViewController(context: Context) -> VideoPlayerContainerViewController {
        VideoPlayerContainerViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: VideoPlayerContainerViewController, context: Context) {
        // No additional update code is required here.
    }
}

/// A UIViewController that creates and manages an AVPlayerLayer tied to the view model's player.
class VideoPlayerContainerViewController: UIViewController {
    private let viewModel: VideoPlayerViewModel
    private var playerLayer: AVPlayerLayer?

    init(viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerLayer()
    }

    private func setupPlayerLayer() {
        guard let player = viewModel.player else { return }
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.playerLayer = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
} 