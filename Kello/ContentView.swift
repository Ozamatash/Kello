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
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 1  // Start on Discover tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(
                modelContext: modelContext,
                isTabActive: selectedTab == 0,
                authViewModel: authViewModel
            )
            .tabItem {
                Label("Feed", systemImage: "play.circle.fill")
            }
            .tag(0)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
            
            #if DEBUG
            // Debug controls - only visible in debug builds
            VStack(spacing: 20) {
                Button(action: {
                    PopulateTestData.populateTestData()
                }) {
                    Text("Reset Data")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    VideoCache.shared.clearCache()
                }) {
                    Text("Clear Video Cache")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
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
        .environmentObject(AuthViewModel())
}
