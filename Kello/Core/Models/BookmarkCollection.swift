import Foundation
import FirebaseFirestore

struct BookmarkCollection: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    var name: String
    var description: String?
    var recipeIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var thumbnailURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case description
        case recipeIds
        case createdAt
        case updatedAt
        case thumbnailURL
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         name: String,
         description: String? = nil,
         recipeIds: [String] = [],
         thumbnailURL: String? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.recipeIds = recipeIds
        self.createdAt = Date()
        self.updatedAt = Date()
        self.thumbnailURL = thumbnailURL
    }
    
    init?(from document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let userId = data["userId"] as? String,
            let name = data["name"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.name = name
        self.description = data["description"] as? String
        self.recipeIds = (data["recipeIds"] as? [String]) ?? []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailURL = data["thumbnailURL"] as? String
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "description": description as Any,
            "recipeIds": recipeIds,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "thumbnailURL": thumbnailURL as Any
        ]
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BookmarkCollection, rhs: BookmarkCollection) -> Bool {
        lhs.id == rhs.id
    }
} 