 import Foundation

struct MockUser {
    let id: String
    let displayName: String
    let profileImage: String?
}

class MockUserGenerator {
    static let mockUsers: [MockUser] = [
        MockUser(id: "user1", displayName: "Emma Wilson", profileImage: "https://i.pravatar.cc/150?u=user1"),
        MockUser(id: "user2", displayName: "James Chen", profileImage: "https://i.pravatar.cc/150?u=user2"),
        MockUser(id: "user3", displayName: "Sofia Rodriguez", profileImage: "https://i.pravatar.cc/150?u=user3"),
        MockUser(id: "user4", displayName: "Alex Kim", profileImage: "https://i.pravatar.cc/150?u=user4"),
        MockUser(id: "user5", displayName: "Maya Patel", profileImage: "https://i.pravatar.cc/150?u=user5"),
        MockUser(id: "user6", displayName: "Lucas Brown", profileImage: "https://i.pravatar.cc/150?u=user6"),
        MockUser(id: "user7", displayName: "Olivia Taylor", profileImage: "https://i.pravatar.cc/150?u=user7"),
        MockUser(id: "user8", displayName: "Ethan Davis", profileImage: "https://i.pravatar.cc/150?u=user8"),
        MockUser(id: "user9", displayName: "Ava Martinez", profileImage: "https://i.pravatar.cc/150?u=user9"),
        MockUser(id: "user10", displayName: "Noah Garcia", profileImage: "https://i.pravatar.cc/150?u=user10")
    ]
    
    static let commentTemplates = [
        "This recipe looks amazing! 😍",
        "I tried this last night and it was delicious!",
        "Love how simple and quick this is to make",
        "The presentation is beautiful",
        "Great healthy option! 🥗",
        "Perfect for meal prep",
        "My family loved this recipe",
        "The flavors are incredible",
        "Thanks for sharing this! 🙏",
        "Adding this to my must-try list",
        "Made this for dinner, turned out perfect! 👨‍🍳",
        "Such a creative twist on a classic",
        "The instructions were so clear and easy to follow",
        "This has become a weekly staple in our house",
        "Love the combination of ingredients"
    ]
    
    static func generateRandomComment(for recipeId: String, withTimestamp: Date? = nil) -> Comment {
        let user = mockUsers.randomElement()!
        let text = commentTemplates.randomElement()!
        let timestamp = withTimestamp ?? Date().addingTimeInterval(-Double.random(in: 0...(86400 * 7))) // Random time in the last week
        let likes = Int.random(in: 0...15)
        
        return Comment(
            userId: user.id,
            recipeId: recipeId,
            text: text,
            timestamp: timestamp,
            likes: likes,
            isLikedByCurrentUser: Bool.random(),
            userDisplayName: user.displayName,
            userProfileImage: user.profileImage
        )
    }
    
    static func generateComments(for recipeId: String, count: Int) -> [Comment] {
        var comments: [Comment] = []
        let now = Date()
        
        for i in 0..<count {
            // Create comments with descending timestamps
            let timestamp = now.addingTimeInterval(-Double(i * 3600)) // Each comment is 1 hour older
            comments.append(generateRandomComment(for: recipeId, withTimestamp: timestamp))
        }
        
        return comments
    }
} 