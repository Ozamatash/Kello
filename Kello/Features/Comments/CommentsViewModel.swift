import Foundation

@MainActor
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    var canPost: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private let recipeId: String
    private let firebaseService: FirebaseService
    
    init(recipeId: String, firebaseService: FirebaseService = FirebaseService.shared) {
        self.recipeId = recipeId
        self.firebaseService = firebaseService
    }
    
    func loadComments() {
        Task {
            isLoading = true
            do {
                comments = try await firebaseService.fetchComments(for: recipeId)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func postComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                let comment = try await firebaseService.addComment(to: recipeId, text: newCommentText)
                comments.insert(comment, at: 0)
                newCommentText = ""
            } catch {
                self.error = error
            }
        }
    }
    
    func toggleLike(for comment: Comment) {
        Task {
            do {
                if comment.isLikedByCurrentUser {
                    try await firebaseService.unlikeComment(comment.id)
                    if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                        comments[index].likes -= 1
                        comments[index].isLikedByCurrentUser = false
                    }
                } else {
                    try await firebaseService.likeComment(comment.id)
                    if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                        comments[index].likes += 1
                        comments[index].isLikedByCurrentUser = true
                    }
                }
            } catch {
                self.error = error
            }
        }
    }
} 