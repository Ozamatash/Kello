import SwiftUI

struct RecipeVideoView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VideoCard(
                recipe: recipe,
                isVisible: true,
                nextVideoURL: nil
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height < -100 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dismiss()
                            }
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
    }
} 