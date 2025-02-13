import Foundation
import OpenAI
import SwiftUI
import AVFoundation

@MainActor
class RecipeAssistantViewModel: ObservableObject {
    
    // MARK: - Properties
    
    private let recipeTitle: String
    private let recipeIngredients: [String]
    private let recipeSteps: [String]
    
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
        // Store recipe data at initialization to avoid actor isolation issues
        self.recipeTitle = recipe.title
        self.recipeIngredients = recipe.ingredients
        self.recipeSteps = recipe.steps
        
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
        
        // Capture recipe data for use in closure
        let instructions = """
            You are an expert cooking assistant helping with: \(recipeTitle).
            
            CONTEXT:
            - Ingredients: \(recipeIngredients.joined(separator: ", "))
            - Steps: \(recipeSteps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: " "))
            
            GUIDELINES:
            - Prioritize clarity and practicality in your responses
            - Adapt your level of detail based on the user's needs
            - Share relevant cooking wisdom and tips when appropriate
            - Help troubleshoot and suggest alternatives if needed
            - Keep responses concise and to the point
            """
        
        Task { @MainActor in
            do {
                try await conversation?.whenConnected { [weak self] in
                    guard let self = self else { return }
                    
                    try await self.conversation?.updateSession { session in
                        session.instructions = instructions
                        session.voice = .alloy
                        session.inputAudioTranscription = .init()
                        
                        // Configure turn detection with faster response time
                        session.turnDetection = .init(
                            type: .serverVad,
                            threshold: 0.85,
                            createResponse: true
                        )
                    }
                    
                    // Dispatch back to main actor
                    Task { @MainActor in
                        self.isConnected = true
                        self.setupRetryCount = 0  // Reset retry count on successful connection
                    }
                }
                
                try conversation?.startListening()
            } catch {
                handleError(error, context: "Connection")
                
                // Attempt to retry setup after a delay
                try? await Task.sleep(for: .seconds(2))
                setupConversation()
            }
        }
    }
    
    private func handleError(_ error: Error, context: String) {
        print("[\(context)] Error: \(error.localizedDescription)")
        isConnected = false
        errorMessage = "[\(context)] \(error.localizedDescription)"
        showError = true
    }
    
    // MARK: - Audio Control
    
    func toggleMute() {
        isMuted.toggle()
        Task {
            if isMuted {
                conversation?.stopListening()
            } else {
                try? conversation?.startListening()
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        // First stop voice handling
        conversation?.stopHandlingVoice()
        // Then null out the conversation reference
        conversation = nil
        
        Task {
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
