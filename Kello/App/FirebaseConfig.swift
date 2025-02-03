import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
        // Test connection
        testConnection()
    }
    
    // MARK: - Auth
    var auth: Auth {
        Auth.auth()
    }
    
    // MARK: - Firestore
    var firestore: Firestore {
        Firestore.firestore()
    }
    
    // MARK: - Storage
    var storage: Storage {
        Storage.storage()
    }
    
    // MARK: - Testing
    private func testConnection() {
        let db = Firestore.firestore()
        db.collection("test").document("connection")
            .setData(["timestamp": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    print("❌ Firebase connection failed: \(error.localizedDescription)")
                } else {
                    print("✅ Firebase successfully connected!")
                }
            }
    }
} 