//
//  KelloApp.swift
//  Kello
//
//  Created by Tuomas Laitila on 3.2.2025.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct KelloApp: App {
    @StateObject private var authState = AuthState()
    
    init() {
        FirebaseConfig.shared.configure()
        
        // Configure URL cache with larger capacity
        let memoryCapacity = 100 * 1024 * 1024    // 100 MB memory cache
        let diskCapacity = 500 * 1024 * 1024      // 500 MB disk cache
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "video_cache")
        URLCache.shared = cache
        
        // Register for memory warnings to clear memory cache if needed
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            URLCache.shared.removeAllCachedResponses()
            print("🧹 Cleared URL cache due to memory warning")
        }
        
        print("📦 URL Cache configured - Memory: \(ByteCountFormatter.string(fromByteCount: Int64(memoryCapacity), countStyle: .file)), Disk: \(ByteCountFormatter.string(fromByteCount: Int64(diskCapacity), countStyle: .file))")
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await signInAnonymously()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func signInAnonymously() async {
        do {
            if Auth.auth().currentUser == nil {
                print("🔑 No user found, signing in anonymously...")
                try await Auth.auth().signInAnonymously()
                print("✅ Anonymous authentication successful")
            }
        } catch {
            print("❌ Anonymous authentication failed: \(error.localizedDescription)")
        }
    }
}
