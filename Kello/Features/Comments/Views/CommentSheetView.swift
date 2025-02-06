import SwiftUI

struct CommentSheetView: View {
    @StateObject var viewModel: CommentsViewModel
    @Binding var isPresented: Bool
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle area
            Rectangle()
                .fill(.clear)
                .frame(height: 40)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { gesture in
                            if gesture.translation.height > 50 {
                                isPresented = false
                            }
                        }
                )
            
            // Title
            Text("Comments")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
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