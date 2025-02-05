import Foundation
import FirebaseAuth

struct UserProfile: Codable {
    let id: String
    var email: String?
    var displayName: String?
    var isAnonymous: Bool
    var createdAt: Date
    var lastLoginAt: Date
    
    // User preferences and stats
    var likedRecipes: [String]
    var bookmarkedRecipes: [String]
    var followingUsers: [String]
    var followers: [String]
    var recipeCount: Int
    
    init(from firebaseUser: User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.isAnonymous = firebaseUser.isAnonymous
        self.createdAt = Date(timeIntervalSince1970: TimeInterval(firebaseUser.metadata.creationDate?.timeIntervalSince1970 ?? 0))
        self.lastLoginAt = Date(timeIntervalSince1970: TimeInterval(firebaseUser.metadata.lastSignInDate?.timeIntervalSince1970 ?? 0))
        
        // Initialize empty collections
        self.likedRecipes = []
        self.bookmarkedRecipes = []
        self.followingUsers = []
        self.followers = []
        self.recipeCount = 0
    }
    
    init(id: String, email: String? = nil, displayName: String? = nil, isAnonymous: Bool = false,
         createdAt: Date = Date(), lastLoginAt: Date = Date(), likedRecipes: [String] = [],
         bookmarkedRecipes: [String] = [], followingUsers: [String] = [], followers: [String] = [],
         recipeCount: Int = 0) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.likedRecipes = likedRecipes
        self.bookmarkedRecipes = bookmarkedRecipes
        self.followingUsers = followingUsers
        self.followers = followers
        self.recipeCount = recipeCount
    }
} 