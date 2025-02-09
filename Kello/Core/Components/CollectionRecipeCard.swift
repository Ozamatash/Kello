import SwiftUI

struct CollectionRecipeCard: View {
    let recipe: Recipe
    var onRemovePressed: (() -> Void)? = nil
    var showRemoveButton: Bool = false
    
    var body: some View {
        RecipeCard(
            recipe: recipe,
            onRemovePressed: onRemovePressed,
            showRemoveButton: showRemoveButton
        )
    }
}

#Preview {
    CollectionRecipeCard(
        recipe: Recipe(
            id: "preview",
            title: "Test Recipe",
            description: "A test recipe",
            cookingTime: 30,
            cuisineType: "Italian",
            ingredients: ["Test ingredient"],
            steps: ["Test step"],
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumbnail.jpg"
        ),
        showRemoveButton: true
    )
    .padding()
} 