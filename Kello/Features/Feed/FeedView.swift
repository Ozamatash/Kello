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
                
                content
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
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.recipes.isEmpty {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else if viewModel.recipes.isEmpty {
            Text("No recipes found")
                .foregroundColor(.white)
        } else {
            videoCardsStack
        }
    }
    
    private var videoCardsStack: some View {
        ZStack {
            ForEach(
                Array(viewModel.recipes.enumerated().prefix(3)),
                id: \.element.id
            ) { index, recipe in
                VideoCard(
                    recipe: recipe,
                    isVisible: index == currentIndex
                )
                .offset(y: calculateOffset(for: index))
                .gesture(createSwipeGesture())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func calculateOffset(for index: Int) -> CGFloat {
        let baseOffset = CGFloat(index - currentIndex) * UIScreen.main.bounds.height
        let activeOffset = index == currentIndex ? dragOffset : 0
        return baseOffset + activeOffset
    }
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded(handleSwipe)
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let verticalThreshold = UIScreen.main.bounds.height * 0.3
        let swipeDistance = value.translation.height
        
        guard abs(swipeDistance) > verticalThreshold else { return }
        
        withAnimation {
            if swipeDistance < 0 && currentIndex < viewModel.recipes.count - 1 {
                currentIndex += 1
            } else if swipeDistance > 0 && currentIndex > 0 {
                currentIndex -= 1
            }
        }
    }
} 