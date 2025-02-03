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
            
            Text("Search")
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .overlay(alignment: .topTrailing) {
            // Temporary button to populate database
            Button(action: {
                PopulateTestData.populateTestData()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
