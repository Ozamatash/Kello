import Foundation
import AVFoundation

struct AssistantMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

// API Request/Response Models
private struct ChatRequest: Codable {
    let model: String
    let modalities: [String]
    let audio: AudioConfig
    let messages: [Message]
    
    struct AudioConfig: Codable {
        let voice: String
        let format: String
    }
    
    struct Message: Codable {
        let role: String
        let content: MessageContent
    }
    
    enum MessageContent: Codable {
        case text(String)
        case multipart([ContentPart])
        
        func encode(to encoder: Encoder) throws {
            switch self {
            case .text(let str):
                var container = encoder.singleValueContainer()
                try container.encode(str)
            case .multipart(let parts):
                var container = encoder.singleValueContainer()
                try container.encode(parts)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .text(str)
            } else if let parts = try? container.decode([ContentPart].self) {
                self = .multipart(parts)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid message content")
            }
        }
    }
    
    struct ContentPart: Codable {
        let type: String
        let text: String?
        let input_audio: AudioData?
        
        struct AudioData: Codable {
            let data: String
            let format: String
        }
    }
}

private struct ChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let role: String
        let content: String?
        let audio: AudioData?
    }
    
    struct AudioData: Codable {
        let data: String
        let transcript: String?
    }
}

@MainActor
class RecipeAssistantViewModel: NSObject, ObservableObject {
    private let recipe: Recipe
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var messages: [AssistantMessage] = []
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var recordingURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recording.wav")
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            handleError("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        // Set up audio recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            handleError("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isProcessing = true
        
        // Process the recording
        processRecording()
    }
    
    private func processRecording() {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            handleError("Recording file not found")
            return
        }
        
        Task {
            do {
                let audioData = try Data(contentsOf: recordingURL)
                let base64Audio = audioData.base64EncodedString()
                
                // Create request body
                let request = ChatRequest(
                    model: "gpt-4o-mini-audio-preview",
                    modalities: ["text", "audio"],
                    audio: .init(voice: "nova", format: "wav"),
                    messages: [
                        .init(
                            role: "system",
                            content: .text("""
                                You are a friendly and helpful cooking assistant. The user is currently cooking: \(recipe.title).
                                Recipe steps: \(recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
                                Ingredients: \(recipe.ingredients.joined(separator: ", "))
                                """)
                        ),
                        .init(
                            role: "user",
                            content: .multipart([
                                .init(
                                    type: "text",
                                    text: "What is in this recording?",
                                    input_audio: nil
                                ),
                                .init(
                                    type: "input_audio",
                                    text: nil,
                                    input_audio: .init(data: base64Audio, format: "wav")
                                )
                            ])
                        )
                    ]
                )
                
                // Create URL request
                var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
                urlRequest.httpBody = try JSONEncoder().encode(request)
                
                print("Sending request to OpenAI...")
                
                // Make API call
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                guard httpResponse.statusCode == 200 else {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("API Error: \(errorJson)")
                    }
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
                }
                
                print("Got response from OpenAI")
                
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                
                if let responseMessage = chatResponse.choices.first?.message {
                    // Add user's transcribed message and assistant's response
                    if let transcript = responseMessage.audio?.transcript {
                        messages.append(AssistantMessage(content: transcript, isUser: true))
                    }
                    
                    if let content = responseMessage.content {
                        messages.append(AssistantMessage(content: content, isUser: false))
                    }
                    
                    // Convert assistant's response to speech
                    if let audioData = Data(base64Encoded: responseMessage.audio?.data ?? "") {
                        print("Got audio data of size: \(audioData.count) bytes")
                        try audioData.write(to: recordingURL)
                        await MainActor.run {
                            playResponse()
                        }
                    } else {
                        print("No audio data in response")
                    }
                }
            } catch {
                await MainActor.run {
                    handleError("Failed to process recording: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func playResponse() {
        do {
            // Make sure the audio session is active and configured for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Create and configure audio player
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1.0
            
            // Start playback
            audioPlayer?.play()
        } catch {
            handleError("Failed to play response: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ message: String) {
        print("Error: \(message)")
        errorMessage = message
        showError = true
    }
}

extension RecipeAssistantViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            handleError("Recording failed to complete successfully")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            handleError("Recording encode error: \(error.localizedDescription)")
        }
    }
}

extension RecipeAssistantViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !flag {
            handleError("Audio playback did not complete successfully")
        }
        isProcessing = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            handleError("Audio playback decode error: \(error.localizedDescription)")
        }
    }
} 