import SwiftUI
import SwiftData

struct VideoCard: View {
    let recipe: Recipe
    let isVisible: Bool
    let nextVideoURL: String?
    @StateObject private var viewModel: FeedViewModel
    @State private var showingDetails = false
    
    init(recipe: Recipe, isVisible: Bool, nextVideoURL: String?, viewModel: FeedViewModel) {
        self.recipe = recipe
        self.isVisible = isVisible
        self.nextVideoURL = nextVideoURL
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Video Player
                VideoPlayerView(
                    videoURL: recipe.videoURL,
                    nextVideoURL: nextVideoURL,
                    isVisible: isVisible
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Content overlay
                RecipeOverlay(
                    recipe: recipe,
                    viewModel: viewModel,
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
    @ObservedObject var viewModel: FeedViewModel
    let onDetailsPressed: () -> Void
    @State private var isLiking = false
    
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
                    Button(action: {
                        guard !isLiking else { return }
                        isLiking = true
                        
                        // Find the index of this recipe
                        if let index = viewModel.recipes.firstIndex(where: { $0.id == recipe.id }) {
                            Task {
                                do {
                                    try await viewModel.likeRecipe(at: index)
                                } catch {
                                    print("Error liking recipe: \(error)")
                                }
                                isLiking = false
                            }
                        }
                    }) {
                        Label(
                            "\(recipe.likes)",
                            systemImage: viewModel.isRecipeLiked(recipe.id) ? "heart.fill" : "heart"
                        )
                        .foregroundColor(viewModel.isRecipeLiked(recipe.id) ? .red : .white)
                        .opacity(isLiking ? 0.5 : 1.0)
                    }
                    .disabled(isLiking)
                    
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
    let container = try! ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
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
        isVisible: true,
        nextVideoURL: nil,
        viewModel: FeedViewModel(
            modelContext: container.mainContext,
            authViewModel: AuthViewModel()
        )
    )
    .frame(height: 400)
    .background(Color.black)
} 