import SwiftUI

struct CommentSheetView: View {
    @StateObject var viewModel: CommentsViewModel
    @Binding var isPresented: Bool
    @FocusState private var isInputFocused: Bool
    
    // For bottom sheet drag gesture
    @GestureState private var dragOffset: CGFloat = 0
    private let sheetHeight: CGFloat = UIScreen.main.bounds.height * 0.67
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // Comment sheet
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Comments")
                            .font(.headline)
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Comments list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            } else if viewModel.comments.isEmpty {
                                Text("No comments yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(viewModel.comments) { comment in
                                    CommentRowView(
                                        comment: comment,
                                        onLikeTapped: { viewModel.toggleLike(for: comment) }
                                    )
                                    
                                    Divider()
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Comment input
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $viewModel.newCommentText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)
                        
                        Button {
                            viewModel.postComment()
                            isInputFocused = false
                        } label: {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                        .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
                .frame(height: sheetHeight)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .offset(y: max(0, dragOffset + (isPresented ? 0 : sheetHeight)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let threshold = sheetHeight * 0.2
                            if value.translation.height > threshold {
                                isPresented = false
                            }
                        }
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            viewModel.loadComments()
        }
    }
}

#Preview {
    CommentSheetView(
        viewModel: CommentsViewModel(recipeId: "test"),
        isPresented: .constant(true)
    )
} 