import SwiftUI

struct RecipeVideoView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isActive = true
    
    var body: some View {
        GeometryReader { geometry in
            VideoCard(
                recipe: recipe,
                isVisible: isActive,
                nextVideoURL: nil
            )
            .offset(y: dragOffset)
            .opacity(calculateOpacity(dragOffset: dragOffset))
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let height = geometry.size.height
                        let threshold = height * 0.2 // 20% of screen height
                        let velocity = abs(value.predictedEndLocation.y - value.location.y)
                        let translation = value.translation.height
                        
                        // Dismiss if dragged far enough or with enough velocity
                        if abs(translation) > threshold || velocity > 500 {
                            // First stop the video
                            isActive = false
                            // Then dismiss after a short delay to ensure cleanup
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dismiss()
                                }
                            }
                        } else {
                            // Snap back if not dragged far enough
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                // dragOffset will automatically reset to 0
                            }
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
        .onDisappear {
            isActive = false
        }
        .onAppear {
            isActive = true
        }
    }
    
    private func calculateOpacity(dragOffset: CGFloat) -> Double {
        let maxOffset: CGFloat = UIScreen.main.bounds.height * 0.2
        let opacity = 1.0 - (abs(dragOffset) / maxOffset) * 0.5 // Fade to 50% opacity
        return max(0.5, opacity) // Don't go below 50% opacity
    }
} 