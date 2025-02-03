import SwiftUI
import SwiftData

struct FeedView: View {
    @State private var viewModel: FeedViewModel
    @State private var currentIndex = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: FeedViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if viewModel.recipes.isEmpty {
                    Text("No recipes found")
                        .foregroundColor(.white)
                } else {
                    // Video cards stack
                    ZStack {
                        ForEach(
                            Array(viewModel.recipes.enumerated().prefix(3)),
                            id: \.element.id
                        ) { index, recipe in
                            VideoCard(recipe: recipe)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .offset(y: calculateOffset(for: index, geometry: geometry))
                                .gesture(
                                    DragGesture()
                                        .updating($dragOffset) { value, state, _ in
                                            state = value.translation.height
                                        }
                                        .onEnded { value in
                                            handleSwipe(value, geometry: geometry)
                                        }
                                )
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 49) // Height of tab bar
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            if newValue >= viewModel.recipes.count - 2 {
                Task {
                    await viewModel.loadMoreRecipes()
                }
            }
        }
        .task {
            await viewModel.loadInitialRecipes()
        }
    }
    
    private func calculateOffset(for index: Int, geometry: GeometryProxy) -> CGFloat {
        let baseOffset = CGFloat(index - currentIndex) * geometry.size.height
        let activeOffset = index == currentIndex ? dragOffset : 0
        return baseOffset + activeOffset
    }
    
    private func handleSwipe(_ value: DragGesture.Value, geometry: GeometryProxy) {
        let verticalThreshold = geometry.size.height * 0.3
        let swipeDistance = value.translation.height
        
        if abs(swipeDistance) > verticalThreshold {
            if swipeDistance < 0 && currentIndex < viewModel.recipes.count - 1 {
                withAnimation {
                    currentIndex += 1
                }
            } else if swipeDistance > 0 && currentIndex > 0 {
                withAnimation {
                    currentIndex -= 1
                }
            }
        }
    }
}

struct VideoCard: View {
    let recipe: Recipe
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.gray
                    .overlay {
                        // TODO: Implement video player
                        Text("Video Placeholder")
                            .foregroundColor(.white.opacity(0.5))
                    }
                
                // Content overlay
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Recipe info overlay
                    VStack(alignment: .leading, spacing: 12) {
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
                        
                        // Engagement metrics
                        HStack(spacing: 20) {
                            Label("\(recipe.likes)", systemImage: "heart.fill")
                                .foregroundColor(.red)
                            Label("\(recipe.comments)", systemImage: "message.fill")
                                .foregroundColor(.blue)
                            Label("\(recipe.shares)", systemImage: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .font(.callout)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .black.opacity(0.3),
                                .black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
} 