import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Time Filters Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cooking Time")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CookingTimeFilter.allCases) { filter in
                                FilterChip(
                                    title: filter.displayText,
                                    isSelected: viewModel.selectedTimeFilter == filter
                                ) {
                                    viewModel.selectTimeFilter(filter)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Cuisine Filters Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cuisine Type")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                                FilterChip(
                                    title: cuisine,
                                    isSelected: viewModel.selectedCuisine == cuisine
                                ) {
                                    viewModel.selectCuisine(cuisine)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
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
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasActiveFilters {
                        Button("Clear All") {
                            viewModel.clearFilters()
                        }
                        .foregroundColor(.accentColor)
                    }
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
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No recipes found")
                .font(.headline)
            Text("Try different filters")
                .font(.subheadline)
                .foregroundColor(.gray)
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