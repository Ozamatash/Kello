import SwiftUI

struct DiscoverView: View {
    @State private var searchTerm = ""
    @State private var recipes: [Recipe] = []
    @State private var isSearching = false
    @State private var searchError: Error?
    
    private let searchService = RecipeSearchService()
    
    var body: some View {
        NavigationView {
            VStack {
                if isSearching {
                    ProgressView("Searching recipes...")
                } else if let error = searchError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Search failed")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if recipes.isEmpty && !searchTerm.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No recipes found")
                            .font(.headline)
                        Text("Try different ingredients or a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(recipes) { recipe in
                                RecipeCard(recipe: recipe)
                            }
                        }
                        .padding()
                    }
                }
            }
            .searchable(
                text: $searchTerm,
                prompt: "Search recipes by ingredients..."
            )
            .onChange(of: searchTerm) { _, newValue in
                // Don't search if the term is empty
                guard !newValue.isEmpty else {
                    recipes = []
                    return
                }
                
                // Debounce the search
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    
                    await search()
                }
            }
            .navigationTitle("Discover Recipes")
        }
    }
    
    private func search() async {
        isSearching = true
        searchError = nil
        
        do {
            recipes = try await searchService.searchRecipes(searchTerm: searchTerm)
        } catch {
            searchError = error
        }
        
        isSearching = false
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailImage
            recipeInfo
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var thumbnailImage: some View {
        AsyncImage(url: URL(string: recipe.thumbnailURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var recipeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Label("\(recipe.cookingTime)m", systemImage: "clock")
                Spacer()
                Label(recipe.cuisineType, systemImage: "fork.knife")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
    }
}

// Preview provider
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
} 