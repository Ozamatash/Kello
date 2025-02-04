import SwiftUI

struct RecipeDetailsSheet: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    @GestureState private var dragState = DragState.inactive
    @State private var position: CGFloat = 0.0 // Start from bottom
    
    private let maxHeight: CGFloat = UIScreen.main.bounds.height * 0.7 // 70% of screen height
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Handle Area
                dragHandle
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        recipeHeader
                        ingredientsSection
                        instructionsSection
                        nutritionSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 80) // Account for bottom bar
                }
            }
            .frame(height: maxHeight)
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 10)
            .offset(y: max(0, dragState.translation.height))
            .offset(y: geometry.size.height * (1 - position))
            .gesture(dragGesture(geometry: geometry))
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    position = 0.7 // Animate to 70% up
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .transition(.move(edge: .bottom))
    }
    
    private var dragHandle: some View {
        VStack(spacing: 0) {
            // Visual handle indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.vertical, 12)
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
    
    private var recipeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.title)
                .font(.title2)
                .bold()
            
            HStack(spacing: 16) {
                Label("\(recipe.cookingTime) min", systemImage: "clock")
                Label(recipe.cuisineType, systemImage: "fork.knife")
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            Text(recipe.recipeDescription)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.gray)
                    Text(ingredient)
                }
                .font(.body)
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .foregroundColor(.gray)
                        .frame(width: 24, alignment: .leading)
                    Text(step)
                }
                .font(.body)
            }
        }
    }
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)
            
            if let calories = recipe.calories {
                nutritionRow(label: "Calories", value: "\(calories) kcal")
            }
            if let protein = recipe.protein {
                nutritionRow(label: "Protein", value: "\(protein)g")
            }
            if let carbs = recipe.carbs {
                nutritionRow(label: "Carbs", value: "\(carbs)g")
            }
            if let fat = recipe.fat {
                nutritionRow(label: "Fat", value: "\(fat)g")
            }
        }
    }
    
    private func nutritionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
    
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($dragState) { drag, state, _ in
                state = .dragging(translation: drag.translation)
            }
            .onEnded { drag in
                let dragPercentage = drag.translation.height / geometry.size.height
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if dragPercentage > 0.15 || drag.predictedEndTranslation.height > 80 { // Made more sensitive
                        position = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isPresented = false
                        }
                    } else {
                        position = 0.7 // Snap back to 70%
                    }
                }
            }
    }
}

// Add corner radius modifier for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        RecipeDetailsSheet(
            recipe: Recipe(
                title: "Test Recipe",
                description: "A delicious test recipe that's perfect for testing the UI.",
                cookingTime: 30,
                cuisineType: "Italian",
                ingredients: ["2 cups flour", "1 cup sugar", "3 eggs", "1 cup milk"],
                steps: [
                    "Mix dry ingredients",
                    "Add wet ingredients",
                    "Stir until combined",
                    "Bake at 350°F for 25 minutes"
                ],
                videoURL: "",
                thumbnailURL: ""
            ),
            isPresented: .constant(true)
        )
    }
} 