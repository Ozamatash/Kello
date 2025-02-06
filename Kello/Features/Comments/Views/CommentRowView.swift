import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    let onLikeTapped: () -> Void
    
    private var timeAgo: String {
        // Simple time ago formatting
        let interval = Calendar.current.dateComponents([.minute, .hour, .day], 
                                                     from: comment.timestamp, 
                                                     to: Date())
        if let days = interval.day, days > 0 {
            return "\(days)d"
        } else if let hours = interval.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = interval.minute {
            return "\(max(1, minutes))m"
        }
        return "now"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile Image
            if let imageURL = comment.userProfileImage {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Username and Comment
                HStack(alignment: .top) {
                    Text(comment.userDisplayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(comment.text)
                        .font(.subheadline)
                }
                
                // Metadata
                HStack(spacing: 16) {
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if comment.likes > 0 {
                        Text("\(comment.likes) likes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Like Button
            Button(action: onLikeTapped) {
                Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                    .foregroundColor(comment.isLikedByCurrentUser ? .red : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    CommentRowView(
        comment: Comment(
            userId: "test",
            recipeId: "recipe1",
            text: "This looks amazing! I'll definitely try this recipe.",
            timestamp: Date().addingTimeInterval(-3600),
            likes: 5,
            isLikedByCurrentUser: true,
            userDisplayName: "John Doe"
        ),
        onLikeTapped: {}
    )
} 