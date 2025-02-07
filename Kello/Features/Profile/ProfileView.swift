import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        // Stats Section
                        HStack(spacing: 32) {
                            // Recipes
                            StatButton(
                                count: viewModel.userRecipes.count,
                                label: "Recipes",
                                systemImage: "fork.knife"
                            )
                            
                            // Collections
                            StatButton(
                                count: viewModel.bookmarkCollections.count,
                                label: "Collections",
                                systemImage: "bookmark.fill"
                            )
                            
                            // Likes
                            StatButton(
                                count: viewModel.likedRecipes.count,
                                label: "Likes",
                                systemImage: "heart.fill"
                            )
                        }
                    }
                    .padding(.vertical)
                    
                    // Content Tabs
                    Picker("Content", selection: $selectedTab) {
                        Text("My Recipes").tag(0)
                        Text("Liked").tag(1)
                        Text("Collections").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .zIndex(1)  // Ensure tabs are above content for tapping
                    
                    // Error View
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Content Grid
                    switch selectedTab {
                    case 0:
                        if viewModel.userRecipes.isEmpty {
                            EmptyStateView(
                                systemImage: "fork.knife",
                                title: "No Recipes Yet",
                                message: "Your created recipes will appear here"
                            )
                        } else {
                            recipesGrid(recipes: viewModel.userRecipes)
                        }
                    case 1:
                        if viewModel.likedRecipes.isEmpty {
                            EmptyStateView(
                                systemImage: "heart",
                                title: "No Liked Recipes",
                                message: "Recipes you like will appear here"
                            )
                        } else {
                            recipesGrid(recipes: viewModel.likedRecipes)
                        }
                    case 2:
                        if viewModel.bookmarkCollections.isEmpty {
                            EmptyStateView(
                                systemImage: "bookmark",
                                title: "No Collections",
                                message: "Create a collection to organize your favorite recipes"
                            )
                        } else {
                            collectionsGrid
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .task {
            await viewModel.loadUserData()
        }
    }
    
    private var collectionsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.bookmarkCollections) { collection in
                    NavigationLink {
                        BookmarkCollectionDetailView(collection: collection)
                    } label: {
                        CollectionCard(collection: collection)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func recipesGrid(recipes: [Recipe]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(recipes) { recipe in
                    CollectionRecipeCard(recipe: recipe)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

private struct StatButton: View {
    let count: Int
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(height: 28)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 40)
    }
}

#Preview {
    ProfileView()
} 