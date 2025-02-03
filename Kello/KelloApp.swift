//
//  KelloApp.swift
//  Kello
//
//  Created by Tuomas Laitila on 3.2.2025.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct KelloApp: App {
    init() {
        FirebaseConfig.shared.configure()
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
        }
        .modelContainer(sharedModelContainer)
    }
}
