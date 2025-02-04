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
            // Ensure currentIndex stays within bounds
            if viewModel.recipes.isEmpty {
                currentIndex = 0
            } else {
                currentIndex = min(max(0, newValue), viewModel.recipes.count - 1)
            }
            
            // Load more if needed
            if newValue >= viewModel.recipes.count - 2 {
                Task {
                    await viewModel.loadMoreRecipes()
                }
            }
        }
        .onChange(of: viewModel.recipes.count) { oldValue, newValue in
            // Ensure currentIndex is valid when recipes array changes
            if newValue == 0 {
                currentIndex = 0
            } else if currentIndex >= newValue {
                currentIndex = newValue - 1
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
                visibleIndices,
                id: \.self
            ) { index in
                VideoCard(
                    recipe: viewModel.recipes[index],
                    isVisible: index == currentIndex
                )
                .offset(y: calculateOffset(for: index))
                .gesture(createSwipeGesture())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var visibleIndices: [Int] {
        guard !viewModel.recipes.isEmpty else { return [] }
        
        // Ensure currentIndex is within bounds
        let safeCurrentIndex = min(max(0, currentIndex), viewModel.recipes.count - 1)
        
        // Calculate visible range
        let start = max(0, safeCurrentIndex - 1)
        let end = min(viewModel.recipes.count - 1, safeCurrentIndex + 1)
        
        // Only create range if valid
        return start <= end ? Array(start...end) : []
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