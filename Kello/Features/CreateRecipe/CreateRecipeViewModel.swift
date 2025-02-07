import Foundation
import FirebaseFirestore
import AVFoundation

@MainActor
class CreateRecipeViewModel: ObservableObject {
    private let firebaseService = FirebaseService.shared
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    func canCreateRecipe(
        title: String,
        description: String,
        ingredients: [String],
        steps: [String],
        videoURL: URL?
    ) -> Bool {
        // Basic validation
        guard !title.isEmpty,
              !description.isEmpty,
              !ingredients.filter({ !$0.isEmpty }).isEmpty,
              !steps.filter({ !$0.isEmpty }).isEmpty,
              videoURL != nil else {
            return false
        }
        return true
    }
    
    func createRecipe(
        title: String,
        description: String,
        cookingTime: Int,
        cuisineType: String,
        mealType: String,
        ingredients: [String],
        steps: [String],
        videoURL: URL?
    ) async {
        guard let videoURL = videoURL else {
            showError = true
            errorMessage = "Please select a video"
            return
        }
        
        isLoading = true
        showError = false
        errorMessage = nil
        
        do {
            // Create recipe using the FirebaseService
            _ = try await firebaseService.createRecipe(
                title: title,
                description: description,
                cookingTime: cookingTime,
                cuisineType: cuisineType,
                mealType: mealType,
                ingredients: ingredients,
                steps: steps,
                videoURL: videoURL
            )
            
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
} 