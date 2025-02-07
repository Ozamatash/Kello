import SwiftUI
import SwiftData

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var currentIndex = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var hasInitiallyLoaded = false
    let isTabActive: Bool
    
    init(modelContext: ModelContext, isTabActive: Bool, viewModel: FeedViewModel) {
        self.isTabActive = isTabActive
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                content
            }
        }
        .task {
            if !hasInitiallyLoaded {
                await viewModel.loadInitialRecipes()
                hasInitiallyLoaded = true
            }
        }
        .onChange(of: isTabActive) { oldValue, newValue in
            // Handle initial load when tab becomes active
            if newValue && !hasInitiallyLoaded {
                Task {
                    await viewModel.loadInitialRecipes()
                    hasInitiallyLoaded = true
                }
            }
            
            // Reset video state when tab becomes inactive
            if !newValue {
                currentIndex = max(0, currentIndex)
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
                    isVisible: (isTabActive || !hasInitiallyLoaded) && index == currentIndex,
                    nextVideoURL: index < viewModel.recipes.count - 1 ? 
                        viewModel.recipes[index + 1].videoURL : nil,
                    viewModel: viewModel
                )
                .offset(y: calculateOffset(for: index))
                .gesture(createSwipeGesture())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var visibleIndices: [Int] {
        guard !viewModel.recipes.isEmpty else { return [] }
        
        // Only show current video when tab is not active
        if !isTabActive {
            return [currentIndex]
        }
        
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
        // Lower the threshold to 15% of the screen height.
        let verticalThreshold = UIScreen.main.bounds.height * 0.15
        // Consider the predicted end translation for a more responsive feel.
        let predictedSwipeDistance = value.predictedEndTranslation.height

        guard abs(predictedSwipeDistance) > verticalThreshold else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.5)) {
            if predictedSwipeDistance < 0 && currentIndex < viewModel.recipes.count - 1 {
                currentIndex += 1
            } else if predictedSwipeDistance > 0 && currentIndex > 0 {
                currentIndex -= 1
            }
        }
    }
} 