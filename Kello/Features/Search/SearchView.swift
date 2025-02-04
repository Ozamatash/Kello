import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding()
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    filterChips
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Results
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.recipes.isEmpty {
                    emptyState
                } else {
                    searchResults
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search recipes, ingredients...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { oldValue, newValue in
                    viewModel.search(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var filterChips: some View {
        HStack(spacing: 8) {
            // Time Filters
            ForEach(CookingTimeFilter.allCases) { filter in
                FilterChip(
                    title: filter.displayText,
                    isSelected: viewModel.selectedTimeFilter == filter
                ) {
                    viewModel.selectTimeFilter(filter)
                }
            }
            
            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)
            
            // Cuisine Filters
            ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                FilterChip(
                    title: cuisine,
                    isSelected: viewModel.selectedCuisine == cuisine
                ) {
                    viewModel.selectCuisine(cuisine)
                }
            }
        }
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                ForEach(viewModel.recipes) { recipe in
                    SearchRecipeCard(recipe: recipe)
                        .onAppear {
                            if recipe == viewModel.recipes.last {
                                viewModel.loadMore()
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("Search for recipes")
                    .font(.headline)
                Text("Try searching for recipes or ingredients")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("No recipes found")
                    .font(.headline)
                Text("Try different keywords or filters")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct SearchRecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            AsyncImage(url: URL(string: recipe.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Title
            Text(recipe.title)
                .font(.headline)
                .lineLimit(2)
            
            // Info
            HStack {
                Label("\(recipe.cookingTime)m", systemImage: "clock")
                Spacer()
                Label(recipe.cuisineType, systemImage: "fork.knife")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

#Preview {
    SearchView()
} 