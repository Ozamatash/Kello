import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchTerm = ""
    @State private var isSearching = false
    @State private var searchError: Error?
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Time filters
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
                        
                        // Cuisine filters
                        ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                            FilterChip(
                                title: cuisine,
                                isSelected: viewModel.selectedCuisine == cuisine
                            ) {
                                viewModel.selectCuisine(cuisine)
                            }
                        }
                        
                        Divider()
                            .frame(height: 24)
                            .padding(.horizontal, 4)
                        
                        // Meal type filters
                        ForEach(MealType.allCases) { type in
                            FilterChip(
                                title: type.rawValue,
                                isSelected: viewModel.selectedMealType == type
                            ) {
                                viewModel.selectMealType(type)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Clear filters button
                if viewModel.hasActiveFilters {
                    Button(action: viewModel.clearFilters) {
                        Text("Clear Filters")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 8)
                }
                
                // Content area
                if isSearching || viewModel.isLoading {
                    ProgressView("Loading recipes...")
                        .padding()
                } else if let error = searchError ?? viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading recipes")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if viewModel.recipes.isEmpty && !searchTerm.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No recipes found")
                            .font(.headline)
                        Text("Try different ingredients or adjust your filters")
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
                            ForEach(viewModel.recipes) { recipe in
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
                // Cancel any existing search task
                searchTask?.cancel()
                
                // Don't search if the term is empty
                guard !newValue.isEmpty else {
                    viewModel.clearSearch()
                    return
                }
                
                // Create new debounced search task
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(800))  // Increased debounce time
                    guard !Task.isCancelled else { return }
                    
                    await search()
                }
            }
            .onDisappear {
                // Cancel any pending search when view disappears
                searchTask?.cancel()
            }
            .navigationTitle("Discover Recipes")
        }
    }
    
    private func search() async {
        isSearching = true
        searchError = nil
        
        do {
            await viewModel.performSearch(searchTerm)
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