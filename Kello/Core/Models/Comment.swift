import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let recipeId: String
    let text: String
    let timestamp: Date
    var likes: Int
    var isLikedByCurrentUser: Bool
    var userDisplayName: String
    var userProfileImage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case recipeId
        case text
        case timestamp
        case likes
        case isLikedByCurrentUser
        case userDisplayName
        case userProfileImage
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         recipeId: String,
         text: String,
         timestamp: Date = Date(),
         likes: Int = 0,
         isLikedByCurrentUser: Bool = false,
         userDisplayName: String,
         userProfileImage: String? = nil) {
        self.id = id
        self.userId = userId
        self.recipeId = recipeId
        self.text = text
        self.timestamp = timestamp
        self.likes = likes
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.userDisplayName = userDisplayName
        self.userProfileImage = userProfileImage
    }
    
    init?(from document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let userId = data["userId"] as? String,
            let recipeId = data["recipeId"] as? String,
            let text = data["text"] as? String,
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
            let userDisplayName = data["userDisplayName"] as? String
        else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.recipeId = recipeId
        self.text = text
        self.timestamp = timestamp
        self.likes = (data["likes"] as? Int) ?? 0
        self.isLikedByCurrentUser = (data["isLikedByCurrentUser"] as? Bool) ?? false
        self.userDisplayName = userDisplayName
        self.userProfileImage = data["userProfileImage"] as? String
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "recipeId": recipeId,
            "text": text,
            "timestamp": Timestamp(date: timestamp),
            "likes": likes,
            "isLikedByCurrentUser": isLikedByCurrentUser,
            "userDisplayName": userDisplayName,
            "userProfileImage": userProfileImage as Any
        ]
    }
} 