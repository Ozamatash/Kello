import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    let onLikeTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
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
            Group {
                if let imageURL = comment.userProfileImage {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 24))
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 24))
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Color(UIColor.separator), lineWidth: 0.5)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Username and timestamp
                HStack {
                    Text(comment.userDisplayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("·")
                        .foregroundStyle(.secondary)
                    
                    Text(timeAgo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Comment text
                Text(comment.text)
                    .font(.subheadline)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Likes and interaction
                HStack(spacing: 16) {
                    Button(action: onLikeTapped) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLikedByCurrentUser ? "heart.fill" : "heart")
                                .font(.system(size: 14))
                            if comment.likes > 0 {
                                Text("\(comment.likes)")
                                    .font(.footnote)
                            }
                        }
                        .foregroundStyle(comment.isLikedByCurrentUser ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack {
        CommentRowView(
            comment: Comment(
                userId: "test",
                recipeId: "recipe1",
                text: "This looks amazing! I'll definitely try this recipe. The presentation is beautiful and the ingredients list seems perfect for what I was looking for.",
                timestamp: Date().addingTimeInterval(-3600),
                likes: 5,
                isLikedByCurrentUser: true,
                userDisplayName: "John Doe"
            ),
            onLikeTapped: {}
        )
        
        Divider()
            .padding(.leading, 60)
        
        CommentRowView(
            comment: Comment(
                userId: "test2",
                recipeId: "recipe1",
                text: "Made this yesterday, turned out great!",
                timestamp: Date().addingTimeInterval(-300),
                likes: 0,
                isLikedByCurrentUser: false,
                userDisplayName: "Jane Smith"
            ),
            onLikeTapped: {}
        )
    }
    .padding(.vertical)
    .background(Color(UIColor.systemBackground))
} 