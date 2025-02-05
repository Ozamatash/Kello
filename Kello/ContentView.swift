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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(modelContext: modelContext, isTabActive: selectedTab == 0)
                .tabItem {
                    Label("Feed", systemImage: "play.circle.fill")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
            
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
            .tag(3)
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
