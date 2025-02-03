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
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            if newValue >= viewModel.recipes.count - 2 {
                viewModel.loadMoreRecipes()
            }
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
        ZStack {
            // TODO: Implement video player
            // For now, just show a placeholder
            Color.gray
            
            VStack {
                Spacer()
                
                // Recipe info overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title2)
                        .bold()
                    
                    Text(recipe.description)
                        .font(.subheadline)
                    
                    HStack {
                        Label("\(recipe.cookingTime) min", systemImage: "clock")
                        Spacer()
                        Label("\(recipe.likes)", systemImage: "heart")
                        Label("\(recipe.comments)", systemImage: "message")
                        Label("\(recipe.shares)", systemImage: "square.and.arrow.up")
                    }
                    .font(.caption)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
} 