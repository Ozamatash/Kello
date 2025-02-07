import SwiftUI

struct CollectionRecipeCard: View {
    let recipe: Recipe
    var onRemovePressed: (() -> Void)? = nil
    var showRemoveButton: Bool = false
    @State private var showingDeleteConfirmation = false
    @State private var showingVideo = false
    
    var body: some View {
        Button {
            showingVideo = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                AsyncImage(url: URL(string: recipe.thumbnailURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    if showRemoveButton {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                }
                
                // Recipe Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(recipe.cookingTime) min", systemImage: "clock")
                        Label(recipe.cuisineType, systemImage: "fork.knife")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .buttonStyle(.plain)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .alert("Remove Recipe?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemovePressed?()
            }
        } message: {
            Text("This recipe will be removed from the collection.")
        }
        .fullScreenCover(isPresented: $showingVideo) {
            RecipeVideoView(recipe: recipe)
        }
    }
}

#Preview {
    CollectionRecipeCard(
        recipe: Recipe(
            id: "test",
            title: "Homemade Italian Pizza with Fresh Mozzarella and Basil",
            description: "A test recipe",
            cookingTime: 30,
            cuisineType: "Italian",
            mealType: "Dinner",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            steps: ["Step 1", "Step 2"],
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumbnail.jpg"
        ),
        showRemoveButton: true
    )
    .padding()
    .previewLayout(.sizeThatFits)
} 