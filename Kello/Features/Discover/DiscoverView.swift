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
                        .padding(.top, 40)
                    } else {
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
    @State private var showingVideo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailImage
            recipeInfo
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(height: 170) // Fixed card height
        .frame(width: 160) // Fixed card width
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                }
        }
        .onTapGesture {
            showingVideo = true
        }
        .fullScreenCover(isPresented: $showingVideo) {
            RecipeVideoView(recipe: recipe)
        }
    }
    
    private var thumbnailImage: some View {
        AsyncImage(url: URL(string: recipe.thumbnailURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color(.systemGray4)
        }
        .frame(height: 100)  // Slightly reduced height
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var recipeInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title)
                .font(.callout)  // Smaller font
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(height: 36)  // Adjusted for smaller font
            
            HStack(spacing: 4) {  // Reduced spacing
                Label {
                    Text("\(recipe.cookingTime)m")
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "clock")
                        .imageScale(.small)
                }
                Spacer(minLength: 4)
                Label {
                    Text(recipe.cuisineType)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "fork.knife")
                        .imageScale(.small)
                }
            }
            .font(.caption2)  // Smaller font
            .foregroundColor(.secondary)
        }
    }
}

// Preview provider
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
} 