import SwiftUI
import PhotosUI
import AVKit

struct VideoPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedURL: URL?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading video...")
                } else {
                    PhotosPicker(selection: $photosPickerItem,
                               matching: .videos,
                               photoLibrary: .shared()) {
                        VStack(spacing: 12) {
                            Image(systemName: "video.badge.plus")
                                .font(.largeTitle)
                            Text("Select Video")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Choose Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: photosPickerItem) { _, newValue in
                guard let item = newValue else { return }
                handleSelectedVideo(item)
            }
        }
    }
    
    private func handleSelectedVideo(_ item: PhotosPickerItem) {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Get video URL from the selected item
                guard let videoData = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load video data"])
                }
                
                // Create a temporary file URL
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString + ".mov")
                
                // Write the video data to the temporary file
                try videoData.write(to: temporaryFileURL)
                
                // Validate video
                let asset = AVAsset(url: temporaryFileURL)
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                
                // Check if video is too long (e.g., > 3 minutes)
                if durationInSeconds > 180 {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video must be shorter than 3 minutes"])
                }
                
                // Update the selected URL on the main thread
                await MainActor.run {
                    selectedURL = temporaryFileURL
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    VideoPicker(selectedURL: .constant(nil))
} 