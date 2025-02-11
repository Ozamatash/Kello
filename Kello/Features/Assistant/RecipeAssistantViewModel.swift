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
        let content: [ContentPart]?  // Changed back to array of ContentPart for user messages
        let audio: AudioConfig?
        
        struct AudioConfig: Codable {
            let id: String
        }
    }
    
    struct ContentPart: Codable {
        let type: String
        let text: String?
        let input_audio: AudioInput?
        
        struct AudioInput: Codable {
            let data: String
            let format: String
        }
    }
}

private struct ChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finish_reason: String
    }
    
    struct Message: Codable {
        let role: String
        let content: String?
        let audio: AudioData?
    }
    
    struct AudioData: Codable {
        let id: String
        let data: String
        let transcript: String?
        let expires_at: TimeInterval?
    }
}

@MainActor
class RecipeAssistantViewModel: NSObject, ObservableObject {
    private let recipe: Recipe
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var lastAssistantAudioId: String? // Only store the ID, not the audio data
    private var conversationHistory: [ChatRequest.Message] = []
    private let maxRetries = 3
    
    @Published var messages: [AssistantMessage] = []
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var canRetry = false
    @Published var lastRequestData: Data?
    
    private var recordingURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recording.wav")
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
        super.init()
        setupAudioSession()
        
        // Add system message to conversation history
        conversationHistory = [
            .init(
                role: "system",
                content: [
                    ChatRequest.ContentPart(
                        type: "text",
                        text: """
                            You are a friendly and helpful cooking assistant. The user is currently cooking: \(recipe.title).
                            Recipe steps: \(recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
                            Ingredients: \(recipe.ingredients.joined(separator: ", "))
                            """,
                        input_audio: nil
                    )
                ],
                audio: nil
            )
        ]
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
    
    private func processRecording(retryCount: Int = 0) {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            handleError("Recording file not found", canRetry: false)
            return
        }
        
        Task {
            do {
                let audioData = try Data(contentsOf: recordingURL)
                let base64Audio = audioData.base64EncodedString()
                
                // Create user message with audio
                let userMessage = ChatRequest.Message(
                    role: "user",
                    content: [
                        ChatRequest.ContentPart(
                            type: "text",
                            text: "What do you think about this?",
                            input_audio: nil
                        ),
                        ChatRequest.ContentPart(
                            type: "input_audio",
                            text: nil,
                            input_audio: .init(
                                data: base64Audio,
                                format: "wav"
                            )
                        )
                    ],
                    audio: nil
                )

                // Build conversation history for this request
                var currentMessages = [
                    ChatRequest.Message(
                        role: "system",
                        content: [
                            ChatRequest.ContentPart(
                                type: "text",
                                text: """
                                    You are a friendly and helpful cooking assistant. The user is currently cooking: \(recipe.title).
                                    Recipe steps: \(recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n"))
                                    Ingredients: \(recipe.ingredients.joined(separator: ", "))
                                    """,
                                input_audio: nil
                            )
                        ],
                        audio: nil
                    )
                ]
                
                // If we have a previous audio response ID, include it
                if let audioId = lastAssistantAudioId {
                    currentMessages.append(.init(
                        role: "assistant",
                        content: nil,
                        audio: .init(id: audioId)
                    ))
                }
                
                // Add the new user message
                currentMessages.append(userMessage)

                // Create request body
                let request = ChatRequest(
                    model: "gpt-4o-mini-audio-preview",
                    modalities: ["text", "audio"],
                    audio: .init(voice: "nova", format: "wav"),
                    messages: currentMessages
                )
                
                // Create URL request
                var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
                let requestBody = try JSONEncoder().encode(request)
                
                // Log the request payload
                let jsonString = createReadableJSON(requestBody)
                print("\n=== Request Payload ===")
                print(jsonString)
                print("=====================\n")
                
                urlRequest.httpBody = requestBody
                
                print("Sending request to OpenAI...")
                
                // Make API call
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                
                // Log the response payload
                let responseString = createReadableJSON(data)
                print("\n=== Response Payload ===")
                print(responseString)
                print("======================\n")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                if httpResponse.statusCode == 500 && retryCount < maxRetries {
                    // Server error, retry after a delay
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)) // Exponential backoff
                    conversationHistory.removeLast() // Remove the last message before retrying
                    await processRecording(retryCount: retryCount + 1)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJson["error"] as? [String: Any] {
                        let errorMessage = error["message"] as? String ?? "Unknown error"
                        let isServerError = httpResponse.statusCode == 500
                        handleError("Assistant unavailable: \(errorMessage)", canRetry: isServerError)
                    }
                    throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
                }
                
                print("Got response from OpenAI")
                
                // Reset error state on successful response
                showError = false
                errorMessage = ""
                canRetry = false
                
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                
                if let responseMessage = chatResponse.choices.first?.message {
                    // Only store the audio ID for future requests
                    if let audioData = responseMessage.audio {
                        lastAssistantAudioId = audioData.id // Store ID for next conversation turn
                        
                        // Play the current audio response
                        if let audioBytes = Data(base64Encoded: audioData.data) {
                            try audioBytes.write(to: recordingURL)
                            await MainActor.run {
                                playResponse()
                            }
                        }
                        
                        // Show transcript in UI if available
                        if let transcript = audioData.transcript {
                            messages.append(AssistantMessage(content: transcript, isUser: true))
                        }
                    }
                    
                    // Show text response in UI if available
                    if let content = responseMessage.content {
                        messages.append(AssistantMessage(content: content, isUser: false))
                    }
                }
            } catch {
                await MainActor.run {
                    let isServerError = (error as NSError).code == 500
                    handleError("Unable to process response: \(error.localizedDescription)", canRetry: isServerError)
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
    
    func retryLastRequest() {
        guard let _ = lastRequestData else { return }
        showError = false
        errorMessage = ""
        canRetry = false
        isProcessing = true
        processRecording()
    }
    
    private func handleError(_ message: String, canRetry: Bool = false) {
        print("Error: \(message)")
        errorMessage = message
        showError = true
        self.canRetry = canRetry
        isProcessing = false
    }
    
    private func createReadableJSON(_ data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Could not parse JSON"
        }
        
        var readableJson = json
        
        // Redact audio data in messages
        if var messages = readableJson["messages"] as? [[String: Any]] {
            for i in 0..<messages.count {
                if var message = messages[i] as? [String: Any],
                   var content = message["content"] as? [[String: Any]] {
                    // Redact input_audio data in multipart content
                    for j in 0..<content.count {
                        if var part = content[j] as? [String: Any],
                           let type = part["type"] as? String,
                           type == "input_audio" {
                            part["input_audio"] = ["data": "[AUDIO DATA REDACTED]", "format": "wav"]
                            content[j] = part
                        }
                    }
                    message["content"] = content
                    messages[i] = message
                }
            }
            readableJson["messages"] = messages
        }
        
        // Redact response audio data
        if var choices = readableJson["choices"] as? [[String: Any]] {
            for i in 0..<choices.count {
                if var choice = choices[i] as? [String: Any],
                   var message = choice["message"] as? [String: Any],
                   var audio = message["audio"] as? [String: Any],
                   let _ = audio["data"] as? String {
                    audio["data"] = "[AUDIO DATA REDACTED]"
                    message["audio"] = audio
                    choice["message"] = message
                    choices[i] = choice
                }
            }
            readableJson["choices"] = choices
        }
        
        // Convert back to JSON string with pretty printing
        let prettyJson = try? JSONSerialization.data(withJSONObject: readableJson, options: .prettyPrinted)
        return String(data: prettyJson ?? data, encoding: .utf8) ?? "Could not format JSON"
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