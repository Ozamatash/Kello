//
//  ContentView.swift
//  Kello
//
//  Created by Tuomas Laitila on 3.2.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            FeedView(modelContext: modelContext)
                .tabItem {
                    Label("Feed", systemImage: "play.circle.fill")
                }
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            #if DEBUG
            // Debug controls - only visible in debug builds
            Button(action: {
                PopulateTestData.populateTestData()
            }) {
                Text("Reset Data")
            }
            .tabItem {
                Label("Test Data", systemImage: "gear")
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
