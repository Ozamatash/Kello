import SwiftUI

struct CommentSheetView: View {
    @StateObject var viewModel: CommentsViewModel
    @Binding var isPresented: Bool
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Title header
            HStack {
                Text("Comments")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !viewModel.comments.isEmpty {
                    Text("\(viewModel.comments.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Comments list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Loading comments...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.comments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("No comments yet")
                                .font(.headline)
                            Text("Be the first to share your thoughts!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ForEach(viewModel.comments) { comment in
                            CommentRowView(
                                comment: comment,
                                onLikeTapped: { viewModel.toggleLike(for: comment) }
                            )
                            
                            Divider()
                                .padding(.leading, 60)  // Align with comment text
                        }
                    }
                }
            }
            
            // Comment input
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Text input with growing height
                    TextField("Add a comment...", text: $viewModel.newCommentText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .focused($isInputFocused)
                        .lineLimit(1...5)
                    
                    // Post button
                    Button {
                        viewModel.postComment()
                        isInputFocused = false
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(viewModel.canPost ? Color.accentColor : Color.gray)
                    }
                    .disabled(!viewModel.canPost)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.background)
                .overlay(alignment: .top) {
                    Divider()
                }
            }
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