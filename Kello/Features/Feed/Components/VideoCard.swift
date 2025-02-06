import SwiftUI
import SwiftData

struct VideoCard: View {
    let recipe: Recipe
    let isVisible: Bool
    let nextVideoURL: String?
    @ObservedObject var viewModel: FeedViewModel
    @State private var showingDetails = false
    @State private var showingComments = false
    
    init(recipe: Recipe, isVisible: Bool, nextVideoURL: String?, viewModel: FeedViewModel) {
        self.recipe = recipe
        self.isVisible = isVisible
        self.nextVideoURL = nextVideoURL
        self.viewModel = viewModel
    }
    
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
                    viewModel: viewModel,
                    onDetailsPressed: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingDetails = true
                        }
                    },
                    onCommentsPressed: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingComments = true
                        }
                    }
                )
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 50) }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showingDetails) {
            RecipeDetailsSheet(
                recipe: recipe,
                isPresented: $showingDetails
            )
            .presentationBackground(.background)
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.75)])
        }
        .sheet(isPresented: $showingComments) {
            CommentSheetView(
                viewModel: CommentsViewModel(recipeId: recipe.id),
                isPresented: $showingComments
            )
            .presentationBackground(.background)
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.75)])
        }
    }
}

private struct RecipeOverlay: View {
    let recipe: Recipe
    @ObservedObject var viewModel: FeedViewModel
    let onDetailsPressed: () -> Void
    let onCommentsPressed: () -> Void
    @State private var isLiking = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Right side: Engagement buttons
            VStack(spacing: 16) {
                // Like Button
                VStack(spacing: 2) {
                    Button(action: {
                        guard !isLiking else { return }
                        isLiking = true
                        
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
                        Image(systemName: recipe.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.system(size: 26))
                            .foregroundColor(recipe.isLikedByCurrentUser ? .red : .white)
                    }
                    
                    Text("\(recipe.likes)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                }
                
                // Comment Button
                VStack(spacing: 2) {
                    Button(action: onCommentsPressed) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(recipe.comments)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                }
                
                // See Recipe Button
                VStack(spacing: 2) {
                    Button(action: onDetailsPressed) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text("Recipe")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Bottom content
            VStack(alignment: .leading, spacing: 8) {
                // Title and description
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.title)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(recipe.recipeDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                // Cooking info row
                HStack(spacing: 16) {
                    Label("\(recipe.cookingTime) min", systemImage: "clock")
                    Label(recipe.cuisineType, systemImage: "fork.knife")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal)
            .padding(.trailing, 64)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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