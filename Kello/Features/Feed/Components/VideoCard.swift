import SwiftUI

struct VideoCard: View {
    let recipe: Recipe
    let isVisible: Bool
    @State private var showingDetails = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Video Player
                VideoPlayerView(
                    videoURL: recipe.videoURL,
                    isVisible: isVisible
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Content overlay
                RecipeOverlay(
                    recipe: recipe,
                    onDetailsPressed: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingDetails = true
                        }
                    }
                )
                
                // Recipe Details Sheet
                if showingDetails {
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    RecipeDetailsSheet(
                        recipe: recipe,
                        isPresented: $showingDetails
                    )
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

private struct RecipeOverlay: View {
    let recipe: Recipe
    let onDetailsPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                // Title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(recipe.recipeDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                // Cooking info
                HStack(spacing: 16) {
                    Label("\(recipe.cookingTime) min", systemImage: "clock")
                    Label(recipe.cuisineType, systemImage: "fork.knife")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                
                // Engagement metrics and details button
                HStack(spacing: 20) {
                    Label("\(recipe.likes)", systemImage: "heart.fill")
                        .foregroundColor(.red)
                    Label("\(recipe.comments)", systemImage: "message.fill")
                        .foregroundColor(.blue)
                    Label("\(recipe.shares)", systemImage: "square.and.arrow.up")
                        .foregroundColor(.green)
                    Spacer()
                    Button(action: onDetailsPressed) {
                        Label("Details", systemImage: "list.bullet")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }
                .font(.callout)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 80)
            .background(overlayGradient)
        }
    }
    
    private var overlayGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .clear,
                .black.opacity(0.3),
                .black.opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    VideoCard(
        recipe: Recipe(
            id: "test",
            title: "Test Recipe",
            description: "A test recipe description that might be a bit longer to test multiple lines",
            cookingTime: 30,
            cuisineType: "Italian",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            steps: ["Step 1", "Step 2"],
            videoURL: "https://example.com/video.mp4",
            thumbnailURL: "https://example.com/thumbnail.jpg",
            calories: 500,
            protein: 20,
            carbs: 30,
            fat: 10
        ),
        isVisible: true
    )
    .frame(height: 400)
    .background(Color.black)
} 