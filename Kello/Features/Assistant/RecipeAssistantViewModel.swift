import Foundation
import OpenAI
import SwiftUI

@MainActor
class RecipeAssistantViewModel: ObservableObject {
    
    // MARK: - Properties
    
    let recipe: Recipe
    @Published var isConnected = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isMuted = false
    
    private var conversation: Conversation?
    
    // MARK: - Initialization
    
    init(recipe: Recipe) {
        self.recipe = recipe
        setupConversation()
    }
    
    private func setupConversation() {
        conversation = Conversation(authToken: OpenAIConfig.apiKey)
        
        Task {
            do {
                try await conversation?.whenConnected { [weak self] in
                    guard let self = self else { return }
                    
                    try await self.conversation?.updateSession { session in
                        session.instructions = """
                            You are a friendly cooking assistant. The current recipe is \(self.recipe.title).
                            Ingredients: \(self.recipe.ingredients.joined(separator: ", ")).
                            Steps: \(self.recipe.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: " "))
                            """
                        session.voice = .alloy
                        session.inputAudioTranscription = .init()
                        
                        // Configure turn detection with faster response time
                        session.turnDetection = .init(
                            type: .serverVad,
                            threshold: 0.7,        // Keep high threshold for noise resistance
                            createResponse: true
                        )
                    }
                    
                    await MainActor.run {
                        self.isConnected = true
                    }
                }
                
                try conversation?.startListening()
            } catch {
                await handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) async {
        print("Error: \(error.localizedDescription)")
        self.isConnected = false
        self.errorMessage = error.localizedDescription
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
        }
    }
}
