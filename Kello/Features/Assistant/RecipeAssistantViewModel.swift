import Foundation
import OpenAI
import SwiftUI
import AVFoundation

@MainActor
class RecipeAssistantViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let recipe: Recipe
    @Published var isConnected = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isMuted = false
    @Published var isReconnecting = false
    
    private var conversation: Conversation?
    private var previousCategory: AVAudioSession.Category?
    private var previousMode: AVAudioSession.Mode?
    private var previousOptions: AVAudioSession.CategoryOptions?
    private var setupRetryCount = 0
    private let maxSetupRetries = 3
    
    // MARK: - Initialization
    
    init(recipe: Recipe) {
        self.recipe = recipe
        setupAudioSession()
        setupConversation()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Store previous configuration
            previousCategory = audioSession.category
            previousMode = audioSession.mode
            previousOptions = audioSession.categoryOptions
            
            // Configure for voice chat
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            handleError(error, context: "Audio Session Setup")
        }
    }
    
    private func setupConversation() {
        guard setupRetryCount < maxSetupRetries else {
            handleError(NSError(domain: "RecipeAssistant", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to setup conversation after multiple attempts"]), context: "Setup")
            return
        }
        
        setupRetryCount += 1
        conversation = Conversation(authToken: OpenAIConfig.apiKey, model: "gpt-4o-mini-realtime-preview")
        
        Task {
            do {
                try await conversation?.whenConnected { [weak self] in
                    guard let self = self else { return }
                    
                    try await self.conversation?.updateSession { session in
                        session.instructions = """
                            You are an expert cooking assistant helping with: \(self.recipe.title).
                            
                            CONTEXT:
                            - Ingredients: \(self.recipe.ingredients.joined(separator: ", "))
                            - Steps: \(self.recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: " "))
                            
                            GUIDELINES:
                            - Prioritize clarity and practicality in your responses
                            - Adapt your level of detail based on the user's needs
                            - Share relevant cooking wisdom and tips when appropriate
                            - Help troubleshoot and suggest alternatives if needed
                            - Keep responses concise and to the point
                            
                            """
                        session.voice = .alloy
                        session.inputAudioTranscription = .init()
                        
                        // Configure turn detection with faster response time
                        session.turnDetection = .init(
                            type: .serverVad,
                            threshold: 0.8,        // Keep high threshold for noise resistance
                            createResponse: true
                        )
                    }
                    
                    await MainActor.run {
                        self.isConnected = true
                        self.setupRetryCount = 0  // Reset retry count on successful connection
                    }
                }
                
                // Monitor connection state
                Task { [weak self] in
                    guard let self = self else { return }
                    while !Task.isCancelled {
                        // Check connection state every second
                        try? await Task.sleep(for: .seconds(1))
                        
                        await MainActor.run {
                            if !self.isConnected {
                                self.handleDisconnection()
                            }
                        }
                    }
                }
                
                try conversation?.startListening()
            } catch {
                await handleError(error, context: "Connection")
                
                // Attempt to retry setup after a delay
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    setupConversation()
                }
            }
        }
    }
    
    private func handleDisconnection() {
        guard !isReconnecting else { return }
        
        isReconnecting = true
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            setupConversation()
            await MainActor.run {
                isReconnecting = false
            }
        }
    }
    
    private func handleError(_ error: Error, context: String) {
        print("[\(context)] Error: \(error.localizedDescription)")
        self.isConnected = false
        self.errorMessage = "[\(context)] \(error.localizedDescription)"
        self.showError = true
    }
    
    // MARK: - Audio Control
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            conversation?.stopListening()
        } else {
            try? conversation?.startListening()
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        Task { @MainActor in
            // First stop voice handling
            conversation?.stopHandlingVoice()
            // Then null out the conversation reference
            conversation = nil
            
            // Restore previous audio session
            let audioSession = AVAudioSession.sharedInstance()
            do {
                if let category = previousCategory,
                   let mode = previousMode,
                   let options = previousOptions {
                    try audioSession.setCategory(category, mode: mode, options: options)
                } else {
                    // Default to playback if no previous configuration
                    try audioSession.setCategory(.playback)
                }
                try audioSession.setActive(true)
            } catch {
                print("Failed to restore audio session: \(error)")
            }
        }
    }
}
