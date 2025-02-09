import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchTerm = ""
    @State private var isSearching = false
    @State private var searchError: Error?
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Filters section
                    VStack(spacing: 12) {
                        // Time filters
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cooking Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                        
                        // Cuisine filters
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cuisine")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    // Clear filters button
                    if viewModel.hasActiveFilters {
                        Button(action: viewModel.clearFilters) {
                            Text("Clear All Filters")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Content area
                    if viewModel.recipes.isEmpty {
                        if isSearching || viewModel.isLoading {
                            ProgressView("Loading recipes...")
                                .padding(.top, 40)
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
                            .padding(.top, 40)
                        } else if !searchTerm.isEmpty {
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
                            .padding(.top, 40)
                        }
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 24) {
                            ForEach(viewModel.recipes) { recipe in
                                RecipeCard(recipe: recipe)
                                    .onAppear {
                                        // If this is one of the last few items, load more
                                        if recipe.id == viewModel.recipes.last?.id ||
                                           viewModel.recipes.suffix(4).contains(where: { $0.id == recipe.id }) {
                                            Task {
                                                await viewModel.loadMoreRecipes()
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                        
                        // Show loading indicator at the bottom while keeping recipes visible
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
            }
            .searchable(
                text: $searchTerm,
                prompt: "Search using natural language..."
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
        
        await viewModel.performSearch(searchTerm)
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

// Preview provider
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
} 