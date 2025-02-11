import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    var onRemovePressed: (() -> Void)? = nil
    var showRemoveButton: Bool = false
    @State private var showingVideo = false
    @State private var loadAttempt = 0
    
    var body: some View {
        Button {
            showingVideo = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Image container with fixed height
                ZStack(alignment: .center) {
                    thumbnailImage
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if showRemoveButton {
                        Button(action: { onRemovePressed?() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                }
                
                // Info container with fixed height
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .layoutPriority(1)
                    
                    HStack(spacing: 4) {
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
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    
                    // Nutritional information
                    if let calories = recipe.caloriesPerServing {
                        HStack(spacing: 4) {
                            Label {
                                Text("\(calories) cal")
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "flame")
                                    .imageScale(.small)
                            }
                            
                            if let servings = recipe.servings {
                                Text("·")
                                Text("\(servings) serv")
                                    .lineLimit(1)
                            }
                            
                            Spacer(minLength: 4)
                            
                            // AI indicator
                            Image(systemName: "sparkles")
                                .imageScale(.small)
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
                .frame(height: 90)  // Increased height to accommodate new line
                .padding(8)
            }
        }
        .frame(width: 160, height: 190)  // Increased total height
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingVideo) {
            RecipeVideoView(recipe: recipe)
        }
    }
    
    private var thumbnailImage: some View {
        AsyncImage(url: URL(string: recipe.thumbnailURL)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color(.systemGray6)
                    ProgressView()
                        .controlSize(.small)
                }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                ZStack {
                    Color(.systemGray6)
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        // Retry button
                        Button {
                            loadAttempt += 1
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.callout)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            @unknown default:
                Color(.systemGray6)
            }
        }
        // Force image reload when loadAttempt changes
        .id(loadAttempt)
        // Add transition for smoother loading states
        .transition(.opacity)
        .animation(.easeInOut, value: loadAttempt)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Normal state
        RecipeCard(
            recipe: Recipe(
                id: "preview1",
                title: "Delicious Recipe With a Very Long Title That Should Wrap",
                description: "A test recipe description",
                cookingTime: 30,
                cuisineType: "Italian",
                ingredients: ["Ingredient 1", "Ingredient 2"],
                steps: ["Step 1", "Step 2"],
                videoURL: "https://example.com/video.mp4",
                thumbnailURL: "https://example.com/thumbnail.jpg"
            )
        )
        
        // With remove button
        RecipeCard(
            recipe: Recipe(
                id: "preview2",
                title: "Short Title",
                description: "A test recipe description",
                cookingTime: 15,
                cuisineType: "Japanese",
                ingredients: ["Ingredient 1", "Ingredient 2"],
                steps: ["Step 1", "Step 2"],
                videoURL: "https://example.com/video.mp4",
                thumbnailURL: "https://example.com/thumbnail.jpg"
            ),
            showRemoveButton: true
        )
        
        // Invalid URL to show error state
        RecipeCard(
            recipe: Recipe(
                id: "preview3",
                title: "Error State Example",
                description: "Shows error state with retry button",
                cookingTime: 45,
                cuisineType: "Mexican",
                ingredients: ["Ingredient 1"],
                steps: ["Step 1"],
                videoURL: "https://example.com/video.mp4",
                thumbnailURL: "invalid-url"
            )
        )
    }
    .padding()
} 