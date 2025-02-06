import SwiftUI

struct CommentSheetView: View {
    @StateObject var viewModel: CommentsViewModel
    @Binding var isPresented: Bool
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title header
            Text("Comments")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
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